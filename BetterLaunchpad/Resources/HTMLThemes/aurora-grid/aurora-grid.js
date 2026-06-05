const canvas = document.getElementById("aurora");
const ctx = canvas.getContext("2d");

let width = 0;
let height = 0;
let dpr = 1;
let pointer = { x: 0.5, y: 0.5, active: false };
let sparks = [];

function resize() {
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    width = window.innerWidth;
    height = window.innerHeight;
    canvas.width = Math.floor(width * dpr);
    canvas.height = Math.floor(height * dpr);
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    createSparks();
}

function createSparks() {
    const count = Math.max(70, Math.floor((width * height) / 18000));
    sparks = Array.from({ length: count }, (_, index) => ({
        x: Math.random() * width,
        y: Math.random() * height,
        size: 0.8 + Math.random() * 2.6,
        drift: 0.18 + Math.random() * 0.55,
        phase: Math.random() * Math.PI * 2,
        color: index % 3 === 0 ? "92, 255, 211" : index % 3 === 1 ? "102, 183, 255" : "255, 135, 225"
    }));
}

window.addEventListener("resize", resize);
window.addEventListener("mousemove", (event) => {
    pointer = {
        x: event.clientX / Math.max(width, 1),
        y: event.clientY / Math.max(height, 1),
        active: true
    };
});
window.addEventListener("mouseleave", () => {
    pointer.active = false;
});

function fillBackground(time) {
    const gradient = ctx.createLinearGradient(0, 0, width, height);
    gradient.addColorStop(0, "#06101f");
    gradient.addColorStop(0.42, "#101a32");
    gradient.addColorStop(1, "#071322");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);

    const glowX = (pointer.active ? pointer.x : 0.72 + Math.sin(time * 0.00017) * 0.12) * width;
    const glowY = (pointer.active ? pointer.y : 0.36 + Math.cos(time * 0.00013) * 0.10) * height;
    const glow = ctx.createRadialGradient(glowX, glowY, 0, glowX, glowY, Math.max(width, height) * 0.58);
    glow.addColorStop(0, "rgba(95, 210, 255, 0.24)");
    glow.addColorStop(0.34, "rgba(168, 105, 255, 0.14)");
    glow.addColorStop(1, "rgba(6, 16, 31, 0)");
    ctx.fillStyle = glow;
    ctx.fillRect(0, 0, width, height);
}

function drawGrid(time) {
    const spacing = 48;
    const offset = (time * 0.012) % spacing;

    ctx.save();
    ctx.globalAlpha = 0.18;
    ctx.strokeStyle = "rgba(150, 220, 255, 0.24)";
    ctx.lineWidth = 1;

    for (let x = -spacing + offset; x < width + spacing; x += spacing) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x + Math.sin(time * 0.00035 + x * 0.01) * 8, height);
        ctx.stroke();
    }

    for (let y = -spacing + offset; y < height + spacing; y += spacing) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(width, y + Math.cos(time * 0.00028 + y * 0.01) * 8);
        ctx.stroke();
    }

    ctx.restore();
}

function drawAuroraBand(time, baseY, colorA, colorB, amplitude, speed, thickness) {
    const gradient = ctx.createLinearGradient(0, baseY - thickness, width, baseY + thickness);
    gradient.addColorStop(0, colorA);
    gradient.addColorStop(0.5, colorB);
    gradient.addColorStop(1, "rgba(0, 0, 0, 0)");

    ctx.save();
    ctx.globalCompositeOperation = "lighter";
    ctx.filter = "blur(18px)";
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.moveTo(0, height);

    for (let x = 0; x <= width; x += 18) {
        const wave1 = Math.sin(x * 0.008 + time * speed) * amplitude;
        const wave2 = Math.cos(x * 0.014 - time * speed * 0.65) * amplitude * 0.42;
        const pointerPull = pointer.active ? Math.sin((x / width - pointer.x) * Math.PI) * 16 * (1 - Math.min(Math.abs(pointer.y - baseY / height), 1)) : 0;
        ctx.lineTo(x, baseY + wave1 + wave2 + pointerPull);
    }

    ctx.lineTo(width, height);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
}

function drawSparks(time) {
    ctx.save();
    ctx.globalCompositeOperation = "lighter";

    for (const spark of sparks) {
        spark.y -= spark.drift;
        spark.x += Math.sin(time * 0.001 + spark.phase) * 0.18;

        if (spark.y < -20) {
            spark.y = height + 20;
            spark.x = Math.random() * width;
        }

        const pulse = 0.45 + Math.sin(time * 0.002 + spark.phase) * 0.35;
        ctx.fillStyle = `rgba(${spark.color}, ${0.16 + pulse * 0.20})`;
        ctx.beginPath();
        ctx.arc(spark.x, spark.y, spark.size, 0, Math.PI * 2);
        ctx.fill();
    }

    ctx.restore();
}

function drawVignette() {
    const gradient = ctx.createRadialGradient(width * 0.5, height * 0.48, 0, width * 0.5, height * 0.5, Math.max(width, height) * 0.72);
    gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
    gradient.addColorStop(0.72, "rgba(0, 0, 0, 0.12)");
    gradient.addColorStop(1, "rgba(0, 0, 0, 0.46)");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
}

function animate(time) {
    fillBackground(time);
    drawGrid(time);
    drawAuroraBand(time, height * 0.38, "rgba(75, 255, 210, 0.00)", "rgba(73, 208, 255, 0.34)", 54, 0.00045, 170);
    drawAuroraBand(time + 900, height * 0.58, "rgba(255, 112, 215, 0.00)", "rgba(153, 111, 255, 0.28)", 42, 0.00038, 150);
    drawAuroraBand(time + 1700, height * 0.74, "rgba(90, 255, 193, 0.00)", "rgba(72, 137, 255, 0.20)", 34, 0.00052, 120);
    drawSparks(time);
    drawVignette();
    requestAnimationFrame(animate);
}

resize();
requestAnimationFrame(animate);
