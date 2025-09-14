/* Hairbnb MVP — client-only, localStorage-backed */
(function () {
  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => Array.from(document.querySelectorAll(sel));

  const nowISODate = () => new Date().toISOString().slice(0, 10);
  const key = {
    hairdressers: 'hb_hairdressers',
    bookings: 'hb_bookings',
    session: 'hb_session',
  };

  let state = {
    hairdressers: [],
    bookings: [],
    session: null, // {type:'guest'|'user'|'hairdresser', name?, email?, hairdresserId?}
  };

  // Storage utils
  function load() {
    state.hairdressers = JSON.parse(localStorage.getItem(key.hairdressers) || '[]');
    state.bookings = JSON.parse(localStorage.getItem(key.bookings) || '[]');
    state.session = JSON.parse(localStorage.getItem(key.session) || 'null') || { type: 'guest', name: 'Guest' };
  }
  function saveHairdressers() { localStorage.setItem(key.hairdressers, JSON.stringify(state.hairdressers)); }
  function saveBookings() { localStorage.setItem(key.bookings, JSON.stringify(state.bookings)); }
  function saveSession() { localStorage.setItem(key.session, JSON.stringify(state.session)); }

  function uid(prefix='id') { return `${prefix}_${Math.random().toString(36).slice(2,9)}`; }

  function seedIfEmpty() {
    if (state.hairdressers.length) return;
    const sample = [
      {
        id: uid('hd'),
        name: 'Fade & Blade',
        email: 'fade@example.com',
        password: 'demo',
        location: 'Downtown',
        services: [
          { name: 'Men Haircut', duration: 30, price: 30 },
          { name: 'Beard Trim', duration: 20, price: 15 },
        ],
        hours: { start: '09:00', end: '18:00' },
      },
      {
        id: uid('hd'),
        name: 'Curl & Care',
        email: 'curl@example.com',
        password: 'demo',
        location: 'Uptown',
        services: [
          { name: 'Wash & Style', duration: 45, price: 40 },
          { name: 'Coloring', duration: 90, price: 120 },
        ],
        hours: { start: '10:00', end: '17:30' },
      },
    ];
    state.hairdressers = sample;
    saveHairdressers();
  }

  // Views
  function switchView(id) {
    $$('.view').forEach(v => v.classList.add('hidden'));
    const el = '#' + id;
    const v = $(el);
    if (v) v.classList.remove('hidden');
    if (id === 'browseView') renderBrowse();
    if (id === 'bookView') initBookingUI();
    if (id === 'myBookingsView') renderMyBookings();
    if (id === 'adminView') renderAdminGate();
  }

  function setUserLabel() {
    const label = $('#currentUserLabel');
    const s = state.session;
    if (!s || s.type === 'guest') label.textContent = 'Guest';
    else if (s.type === 'user') label.textContent = s.name || 'User';
    else if (s.type === 'hairdresser') label.textContent = `${getHairdresserById(s.hairdresserId)?.name || 'Admin'}`;
    $('#openLogin').classList.toggle('hidden', s?.type === 'hairdresser' || s?.type === 'user');
    $('#logoutBtn').classList.toggle('hidden', !(s && (s.type === 'hairdresser' || s.type === 'user')));
  }

  // Helpers
  const getHairdresserById = (id) => state.hairdressers.find(h => h.id === id);
  const getServiceNames = (h) => (h?.services || []).map(s => s.name);

  // Browse rendering
  function renderBrowse(filter = '') {
    const wrap = $('#hairdresserList');
    wrap.innerHTML = '';
    const term = filter.trim().toLowerCase();
    const items = state.hairdressers.filter(h => {
      if (!term) return true;
      return (
        h.name.toLowerCase().includes(term) ||
        (h.location || '').toLowerCase().includes(term) ||
        getServiceNames(h).some(n => n.toLowerCase().includes(term))
      );
    });
    for (const h of items) {
      const card = document.createElement('div');
      card.className = 'card';
      card.innerHTML = `
        <div class="title">${h.name}</div>
        <div class="muted">${h.location || '—'}</div>
        <div class="chips">
          ${(h.services||[]).map(s => `<span class="chip">${s.name} · $${s.price}</span>`).join('') || '<span class="muted">No services yet</span>'}
        </div>
        <div class="row right gap">
          <button data-book-hid="${h.id}">Book</button>
        </div>
      `;
      wrap.appendChild(card);
    }
    // Bind book buttons
    $$('button[data-book-hid]').forEach(btn => btn.addEventListener('click', (e) => {
      const hid = e.currentTarget.getAttribute('data-book-hid');
      $('#bookHairdresser').value = hid;
      switchView('bookView');
      updateBookingServices();
    }));
  }

  // Booking
  function initBookingUI() {
    // Hairdresser select
    const selH = $('#bookHairdresser');
    selH.innerHTML = state.hairdressers.map(h => `<option value="${h.id}">${h.name}</option>`).join('');
    // Services
    updateBookingServices();
    // Date
    const date = $('#bookDate');
    const today = nowISODate();
    date.value = today;
    date.min = today;
    // Times
    updateBookingTimes();
  }

  function updateBookingServices() {
    const hid = $('#bookHairdresser').value || state.hairdressers[0]?.id;
    if (!hid) return;
    const h = getHairdresserById(hid);
    const selS = $('#bookService');
    selS.innerHTML = (h?.services || []).map(s => `<option value="${s.name}">${s.name} · $${s.price}</option>`).join('');
    updateBookingTimes();
  }

  function timeToMinutes(t) { const [H,M] = t.split(':').map(Number); return H*60+M; }
  function minutesToTime(m) { const H = String(Math.floor(m/60)).padStart(2,'0'); const M = String(m%60).padStart(2,'0'); return `${H}:${M}`; }
  function generateSlots(start, end, step=30) {
    const s = timeToMinutes(start), e = timeToMinutes(end);
    const out = [];
    for (let m = s; m+step <= e; m += step) out.push(minutesToTime(m));
    return out;
  }

  function bookedTimesFor(hid, date) {
    return state.bookings.filter(b => b.hairdresserId === hid && b.date === date).map(b => b.time);
  }

  function updateBookingTimes() {
    const hid = $('#bookHairdresser').value || state.hairdressers[0]?.id;
    if (!hid) return;
    const h = getHairdresserById(hid);
    const date = $('#bookDate').value || nowISODate();
    const times = generateSlots(h?.hours?.start || '09:00', h?.hours?.end || '18:00', 30);
    const taken = new Set(bookedTimesFor(hid, date));
    const selT = $('#bookTime');
    selT.innerHTML = times.map(t => `<option value="${t}" ${taken.has(t)?'disabled':''}>${t}${taken.has(t)?' (booked)':''}</option>`).join('');
  }

  function submitBooking() {
    const s = state.session || { type: 'guest', name: 'Guest' };
    const name = s.type === 'user' ? (s.name || 'Guest') : s.type === 'guest' ? 'Guest' : (s.email || 'Client');
    const hid = $('#bookHairdresser').value;
    const service = $('#bookService').value;
    const date = $('#bookDate').value;
    const time = $('#bookTime').value;
    if (!hid || !service || !date || !time) return showMsg('#bookMsg', 'Please fill all fields', true);
    // Check if time free
    if (bookedTimesFor(hid, date).includes(time)) return showMsg('#bookMsg', 'Selected time already booked', true);
    state.bookings.push({ id: uid('bk'), userName: name, hairdresserId: hid, service, date, time, createdAt: Date.now() });
    saveBookings();
    showMsg('#bookMsg', 'Booked successfully!', false);
    renderMyBookings();
  }

  function renderMyBookings() {
    const list = $('#myBookingsList');
    const s = state.session || { type: 'guest', name: 'Guest' };
    let items = [];
    if (s.type === 'hairdresser' && s.hairdresserId) items = state.bookings.filter(b => b.hairdresserId === s.hairdresserId);
    else items = state.bookings.filter(b => b.userName === (s.name || 'Guest'));
    items.sort((a,b)=> a.date.localeCompare(b.date) || a.time.localeCompare(b.time));
    list.innerHTML = items.map(b => {
      const h = getHairdresserById(b.hairdresserId);
      return `<div class="item">
        <div><strong>${b.service}</strong> with ${h?.name || '—'}</div>
        <div class="muted">${b.date} at ${b.time}</div>
        ${s.type==='hairdresser' ? `<div class="muted">Client: ${b.userName}</div>` : ''}
      </div>`;
    }).join('') || '<div class="muted">No bookings yet.</div>';
  }

  // Admin
  function renderAdminGate() {
    const isAdmin = state.session?.type === 'hairdresser';
    $('#adminGate').classList.toggle('hidden', isAdmin);
    $('#adminPanel').classList.toggle('hidden', !isAdmin);
    $('#createAccount').classList.toggle('hidden', isAdmin);
    if (isAdmin) renderAdminPanel();
  }

  function renderAdminPanel() {
    const hid = state.session?.hairdresserId;
    const h = getHairdresserById(hid);
    if (!h) return;
    $('#adminName').value = h.name || '';
    $('#adminLocation').value = h.location || '';
    $('#startHour').value = h.hours?.start || '09:00';
    $('#endHour').value = h.hours?.end || '18:00';
    renderServicesList(h);
  }

  function renderServicesList(h) {
    const wrap = $('#servicesList');
    wrap.innerHTML = (h.services||[]).map((s,i)=> `<span class="chip">${s.name} · ${s.duration}m · $${s.price} <span class="del" data-del-svc="${i}">✕</span></span>`).join('');
    $$('[data-del-svc]').forEach(el => el.addEventListener('click', (e)=>{
      const idx = Number(e.currentTarget.getAttribute('data-del-svc'));
      const hid = state.session.hairdresserId;
      const h = getHairdresserById(hid);
      if (!h) return;
      (h.services||[]).splice(idx,1);
      saveHairdressers();
      renderServicesList(h);
    }));
  }

  // Messages
  function showMsg(sel, text, isErr=false) {
    const el = $(sel);
    el.textContent = text;
    el.classList.remove('ok','err');
    el.classList.add(isErr ? 'err' : 'ok');
    window.setTimeout(()=>{ el.textContent=''; el.classList.remove('ok','err'); }, 2500);
  }

  // Auth Modal
  function openLoginModal(tab='userTab') {
    const dlg = $('#loginModal');
    dlg.showModal();
    switchLoginTab(tab);
  }
  function closeLoginModal() { $('#loginModal').close(); }
  function switchLoginTab(id) {
    $$('.tab').forEach(t=>t.classList.toggle('active', t.getAttribute('data-tab')===id));
    $$('.tabpane').forEach(p=>p.classList.toggle('hidden', p.id!==id));
  }

  // Event wiring
  function wireEvents() {
    // Navigation
    $$('.nav .link').forEach(btn => btn.addEventListener('click', (e) => {
      const view = e.currentTarget.getAttribute('data-view');
      switchView(view);
    }));
    // Login UI
    $('#openLogin').addEventListener('click', () => openLoginModal('userTab'));
    $('#goToLoginFromAdmin').addEventListener('click', () => openLoginModal('hairdresserTab'));
    $('#logoutBtn').addEventListener('click', () => {
      state.session = { type: 'guest', name: 'Guest' };
      saveSession();
      setUserLabel();
      renderAdminGate();
      renderMyBookings();
    });

    // Login modal interactions
    $$('.tab').forEach(t => t.addEventListener('click', (e) => switchLoginTab(e.currentTarget.getAttribute('data-tab'))));
    $('#continueAsGuest').addEventListener('click', () => { state.session = { type: 'guest', name: 'Guest' }; saveSession(); setUserLabel(); closeLoginModal(); });
    $('#userLoginBtn').addEventListener('click', (e) => {
      e.preventDefault();
      const name = ($('#userName').value || '').trim();
      state.session = name ? { type: 'user', name } : { type: 'guest', name: 'Guest' };
      saveSession();
      setUserLabel();
      closeLoginModal();
    });
    $('#hairdresserLoginBtn').addEventListener('click', (e)=>{
      e.preventDefault();
      const email = ($('#loginEmail').value || '').trim().toLowerCase();
      const pass = $('#loginPassword').value || '';
      const h = state.hairdressers.find(x => x.email.toLowerCase()===email && x.password===pass);
      if (!h) return; // silent fail for MVP; could show error
      state.session = { type: 'hairdresser', email, hairdresserId: h.id };
      saveSession();
      setUserLabel();
      closeLoginModal();
      renderAdminGate();
    });

    // Search
    $('#searchInput').addEventListener('input', (e) => renderBrowse(e.target.value));
    $('#clearSearch').addEventListener('click', () => { $('#searchInput').value = ''; renderBrowse(''); });

    // Booking form changes
    $('#bookHairdresser').addEventListener('change', updateBookingServices);
    $('#bookService').addEventListener('change', updateBookingTimes);
    $('#bookDate').addEventListener('change', updateBookingTimes);
    $('#submitBooking').addEventListener('click', submitBooking);

    // Admin panel
    $('#saveProfile').addEventListener('click', () => {
      const hid = state.session?.hairdresserId; const h = getHairdresserById(hid); if (!h) return;
      h.name = $('#adminName').value || h.name;
      h.location = $('#adminLocation').value || '';
      saveHairdressers();
      setUserLabel();
      renderBrowse($('#searchInput').value);
      showMsg('#regMsg', 'Profile saved');
    });
    $('#addService').addEventListener('click', () => {
      const hid = state.session?.hairdresserId; const h = getHairdresserById(hid); if (!h) return;
      const name = ($('#svcName').value||'').trim();
      const duration = Number($('#svcDuration').value||0);
      const price = Number($('#svcPrice').value||0);
      if (!name || !duration) return;
      h.services = h.services || [];
      h.services.push({ name, duration, price });
      saveHairdressers();
      $('#svcName').value = ''; $('#svcDuration').value=''; $('#svcPrice').value='';
      renderServicesList(h);
      renderBrowse($('#searchInput').value);
    });
    $('#saveHours').addEventListener('click', () => {
      const hid = state.session?.hairdresserId; const h = getHairdresserById(hid); if (!h) return;
      const start = $('#startHour').value || '09:00';
      const end = $('#endHour').value || '18:00';
      h.hours = { start, end };
      saveHairdressers();
      showMsg('#regMsg', 'Working hours saved');
    });

    // Registration
    $('#registerHairdresser').addEventListener('click', () => {
      const name = ($('#regName').value||'').trim();
      const email = ($('#regEmail').value||'').trim().toLowerCase();
      const password = $('#regPassword').value||'';
      const location = ($('#regLocation').value||'').trim();
      if (!name || !email || !password) return showMsg('#regMsg','Please fill required fields', true);
      if (state.hairdressers.some(h => h.email.toLowerCase()===email)) return showMsg('#regMsg','Email already registered', true);
      const h = { id: uid('hd'), name, email, password, location, services: [], hours: { start: '09:00', end: '18:00' } };
      state.hairdressers.push(h);
      saveHairdressers();
      showMsg('#regMsg', 'Account created. You can login now.', false);
      renderBrowse($('#searchInput').value);
    });
  }

  // Init
  function init() {
    load();
    seedIfEmpty();
    wireEvents();
    setUserLabel();
    switchView('browseView');
  }

  document.addEventListener('DOMContentLoaded', init);
})();

