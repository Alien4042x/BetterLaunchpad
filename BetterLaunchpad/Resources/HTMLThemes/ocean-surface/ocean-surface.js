const canvas = document.getElementById("ocean");
const ctx = canvas.getContext("2d");

let width = 0;
let height = 0;
let scale = 1;
let lastFrame = 0;
let time = 0;
let ripples = [];
let sparkles = [];
let mouse = { x: 0, y: 0, tx: 0, ty: 0, active: 0 };

const targetFrameMs = 1000 / 42;

function resize() {
    width = window.innerWidth;
    height = window.innerHeight;
    scale = Math.min(window.devicePixelRatio || 1, 1.25);
    canvas.width = Math.round(width * scale);
    canvas.height = Math.round(height * scale);
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
    ctx.setTransform(scale, 0, 0, scale, 0, 0);
    createSparkles();
}

function createSparkles() {
    const density = Math.min(1, Math.sqrt((1920 * 1080) / Math.max(1, width * height)));
    const count = Math.max(36, Math.round(84 * density));
    sparkles = Array.from({ length: count }, () => ({
        x: Math.random() * width,
        y: Math.random() * height,
        phase: Math.random() * Math.PI * 2,
        speed: 0.004 + Math.random() * 0.010,
        radius: 0.7 + Math.random() * 1.4,
        drift: 0.10 + Math.random() * 0.28
    }));
}

function setMouse(x, y) {
    mouse.tx = x;
    mouse.ty = y;
    mouse.active = 1;

    if (ripples.length === 0 || Math.random() < 0.26) {
        ripples.push({ x, y, radius: 8, life: 1 });
        if (ripples.length > 8) {
            ripples.shift();
        }
    }
}

window.addEventListener("resize", resize);
window.addEventListener("mousemove", (event) => setMouse(event.clientX, event.clientY));
window.addEventListener("mouseleave", () => {
    mouse.active = 0;
});

function drawBackground() {
    const gradient = ctx.createLinearGradient(0, 0, 0, height);
    gradient.addColorStop(0, "#102438");
    gradient.addColorStop(0.45, "#061522");
    gradient.addColorStop(1, "#02070c");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);

    const glowX = width * 0.5 + Math.sin(time * 0.004) * width * 0.16;
    const glow = ctx.createRadialGradient(glowX, height * 0.04, 0, glowX, height * 0.04, height * 0.82);
    glow.addColorStop(0, "rgba(80, 188, 226, 0.16)");
    glow.addColorStop(0.35, "rgba(30, 120, 170, 0.07)");
    glow.addColorStop(1, "rgba(3, 9, 16, 0)");
    ctx.fillStyle = glow;
    ctx.fillRect(0, 0, width, height);
}

function drawCaustics() {
    ctx.save();
    ctx.globalCompositeOperation = "lighter";
    ctx.lineWidth = 1;

    const spacing = Math.max(30, width / 48);
    const rows = Math.ceil(height / spacing) + 3;

    for (let row = -1; row < rows; row += 1) {
        const yBase = row * spacing;
        const alpha = 0.045 + 0.032 * Math.sin(row * 0.7 + time * 0.012);
        ctx.strokeStyle = `rgba(116, 218, 246, ${alpha})`;
        ctx.beginPath();

        for (let x = -20; x <= width + 20; x += 24) {
            const wave1 = Math.sin(x * 0.011 + row * 1.2 + time * 0.018) * 10;
            const wave2 = Math.sin(x * 0.026 - time * 0.011) * 4;
            const y = yBase + wave1 + wave2;
            if (x === -20) {
                ctx.moveTo(x, y);
            } else {
                ctx.lineTo(x, y);
            }
        }

        ctx.stroke();
    }

    ctx.restore();
}

function drawRipples() {
    ctx.save();
    ctx.globalCompositeOperation = "lighter";

    for (let i = ripples.length - 1; i >= 0; i -= 1) {
        const ripple = ripples[i];
        ripple.radius += 2.3;
        ripple.life -= 0.020;

        if (ripple.life <= 0) {
            ripples.splice(i, 1);
            continue;
        }

        const pulse = 0.5 + 0.5 * Math.sin(time * 0.08 + ripple.radius * 0.08);
        ctx.lineWidth = 1.1 + pulse;
        ctx.strokeStyle = `rgba(145, 230, 255, ${ripple.life * 0.26})`;
        ctx.beginPath();
        ctx.arc(ripple.x, ripple.y, ripple.radius, 0, Math.PI * 2);
        ctx.stroke();
    }

    mouse.x += (mouse.tx - mouse.x) * 0.08;
    mouse.y += (mouse.ty - mouse.y) * 0.08;
    mouse.active *= 0.982;

    if (mouse.active > 0.02) {
        const radius = Math.min(width, height) * 0.22;
        const glow = ctx.createRadialGradient(mouse.x, mouse.y, 0, mouse.x, mouse.y, radius);
        glow.addColorStop(0, `rgba(160, 238, 255, ${0.16 * mouse.active})`);
        glow.addColorStop(0.35, `rgba(50, 166, 214, ${0.07 * mouse.active})`);
        glow.addColorStop(1, "rgba(0, 0, 0, 0)");
        ctx.fillStyle = glow;
        ctx.fillRect(0, 0, width, height);
    }

    ctx.restore();
}

function drawSparkles() {
    ctx.save();
    ctx.globalCompositeOperation = "lighter";

    for (const item of sparkles) {
        item.x += Math.sin(time * item.speed + item.phase) * item.drift;
        item.y += Math.cos(time * item.speed * 0.7 + item.phase) * item.drift * 0.45;

        if (item.x < -10) item.x = width + 10;
        if (item.x > width + 10) item.x = -10;

        const dx = item.x - mouse.x;
        const dy = item.y - mouse.y;
        const dist = Math.hypot(dx, dy);
        const boost = Math.max(0, 1 - dist / 170) * mouse.active;
        const alpha = 0.07 + boost * 0.42 + 0.06 * Math.sin(time * item.speed + item.phase);
        ctx.fillStyle = `rgba(175, 238, 255, ${alpha})`;
        ctx.beginPath();
        ctx.arc(item.x, item.y, item.radius + boost * 1.8, 0, Math.PI * 2);
        ctx.fill();
    }

    ctx.restore();
}

function render(timestamp) {
    if (timestamp - lastFrame < targetFrameMs) {
        requestAnimationFrame(render);
        return;
    }

    lastFrame = timestamp;
    time += 1;
    drawBackground();
    drawCaustics();
    drawRipples();
    drawSparkles();
    requestAnimationFrame(render);
}

resize();
requestAnimationFrame(render);
