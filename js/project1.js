// === LANG TOGGLE ===
let currentLang = 'en';

function setLang(lang) {
    currentLang = lang;

    // Update all elements with data-en / data-id
    document.querySelectorAll('[data-en], [data-id]').forEach(el => {
        const text = el.getAttribute(`data-${lang}`);
        if (!text) return;
        // Preserve inner HTML for elements that use <em> etc.
        if (text.includes('<')) {
        el.innerHTML = text;
        } else {
        el.textContent = text;
        }
    });

    // Update placeholders that use data-placeholder-en / data-placeholder-id
    document.querySelectorAll('[data-placeholder-en], [data-placeholder-id]').forEach(el => {
        const ph = el.getAttribute(`data-placeholder-${lang}`);
        if (ph) el.placeholder = ph;
    });

    // Update active state on all toggle buttons
    ['btn-id', 'btn-en', 'btn-id-m', 'btn-en-m'].forEach(id => {
        const btn = document.getElementById(id);
        if (!btn) return;
        const btnLang = id.includes('-en') ? 'en' : 'id';
        btn.classList.toggle('active', btnLang === lang);
    });
};

// === NAVBAR SCROLL EFFECT ===
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
    if (window.scrollY > 20) {
        navbar.classList.add('bg-white/95', 'backdrop-blur', 'shadow-sm');
    } else {
        navbar.classList.remove('bg-white/95', 'backdrop-blur', 'shadow-sm');
    }
});

// === SCROLL PROGRES BAR ===
const progressBar = document.getElementById('progress-bar');
window.addEventListener('scroll', () => {
    const totalHeight = document.body.scrollHeight - window.innerHeight;
    const progress = (window.scrollY / totalHeight) * 100;
    if (progressBar) progressBar.style.width = progress + '%';
});

// === BACK TO TOP ===
const btt = document.getElementById('backToTop');
window.addEventListener('scroll', () => {
    btt.classList.toggle('show', window.scrollY > 400);
});

// === CHART ===
Chart.defaults.font.family = "'DM Sans', sans-serif";

new Chart(document.getElementById('lineChart'), {
    type: 'line',
    data: {
        labels: ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'],
        datasets: [{
        label: 'Net Sales (Rp M)',
        data: [27.6, 10.6, 38.1, 38.9, 16.0, 58.4, 20.9, 10.9, 10.3, 9.3, 22.9, 34.1],
        borderColor: '#4ade80', backgroundColor: 'rgba(74,222,128,.1)',
        borderWidth: 2, fill: true, tension: 0.4,
        pointBackgroundColor: '#4ade80', pointRadius: 3, pointHoverRadius: 5
        }]
    },
    options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
        x: { ticks: { color: '#9ca3af', font: { size: 8 }, maxRotation: 0 }, grid: { color: '#2d3748' } },
        y: { ticks: { color: '#9ca3af', font: { size: 8 }, callback: v => v + 'M' }, grid: { color: '#2d3748' } }
        }
    }
});

new Chart(document.getElementById('donutChart'), {
    type: 'doughnut',
    data: {
        labels: ['Peripherals', 'Electronics', 'Accessories', 'Furniture'],
        datasets: [{ data: [466, 460, 452, 428], backgroundColor: ['#4ade80','#22c55e','#16a34a','#166534'], borderColor: '#1a1f2e', borderWidth: 3 }]
    },
    options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { position: 'right', labels: { color: '#9ca3af', font: { size: 8 }, boxWidth: 9, padding: 8 } } }
    }
});

new Chart(document.getElementById('barChart'), {
    type: 'bar',
    data: {
        labels: ['Laptop Pro X1','4K Monitor','Gaming Chair','Headset','Mech. Keyboard'],
        datasets: [{ label: 'Net Sales (Rp M)', data: [260.1, 141.4, 136.7, 105.9, 49.0], backgroundColor: ['#4ade80','#22c55e','#16a34a','#15803d','#166534'], borderRadius: 5 }]
    },
    options: {
        indexAxis: 'y', responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
        x: { ticks: { color: '#9ca3af', font: { size: 8 }, callback: v => v + 'M' }, grid: { color: '#2d3748' } },
        y: { ticks: { color: '#d1d5db', font: { size: 8 } }, grid: { display: false } }
        }
    }
});


// === INIT ===
setLang('en');