const canvas = document.getElementById("nebula");
const ctx = canvas.getContext("2d");

let width = 0;
let height = 0;
let scale = 1;
let time = 0;
let lastFrame = 0;
let backgroundCanvas = null;
let cloudSprites = new Map();
let clouds = [];
let stars = [];
let mouse = { x: 0, y: 0, tx: 0, ty: 0, active: 0 };

const targetFrameMs = 1000 / 40;
const palette = [
    [82, 47, 170],
    [28, 118, 184],
    [184, 62, 146],
    [41, 190, 181],
    [218, 128, 68]
];

function resize() {
    width = window.innerWidth;
    height = window.innerHeight;
    scale = Math.min(window.devicePixelRatio || 1, 1.15);
    canvas.width = Math.round(width * scale);
    canvas.height = Math.round(height * scale);
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
    ctx.setTransform(scale, 0, 0, scale, 0, 0);
    createBackground();
    createCloudSprites();
    createClouds();
    createStars();
}

function createBackground() {
    backgroundCanvas = document.createElement("canvas");
    backgroundCanvas.width = Math.max(1, Math.round(width));
    backgroundCanvas.height = Math.max(1, Math.round(height));

    const bg = backgroundCanvas.getContext("2d");
    const gradient = bg.createRadialGradient(
        width * 0.52,
        height * 0.42,
        0,
        width * 0.52,
        height * 0.42,
        Math.max(width, height)
    );
    gradient.addColorStop(0, "#111735");
    gradient.addColorStop(0.42, "#07071a");
    gradient.addColorStop(1, "#020107");
    bg.fillStyle = gradient;
    bg.fillRect(0, 0, width, height);
}

function createCloudSprites() {
    cloudSprites.clear();

    for (const color of palette) {
        const key = color.join(",");
        const sprite = document.createElement("canvas");
        const size = 192;
        sprite.width = size;
        sprite.height = size;

        const spriteCtx = sprite.getContext("2d");
        const radius = size * 0.5;
        const [r, g, b] = color;
        const gradient = spriteCtx.createRadialGradient(radius, radius, 0, radius, radius, radius);
        gradient.addColorStop(0, `rgba(${r}, ${g}, ${b}, 0.95)`);
        gradient.addColorStop(0.40, `rgba(${r}, ${g}, ${b}, 0.34)`);
        gradient.addColorStop(1, "rgba(0, 0, 0, 0)");
        spriteCtx.fillStyle = gradient;
        spriteCtx.fillRect(0, 0, size, size);
        cloudSprites.set(key, sprite);
    }
}

function createClouds() {
    const density = Math.min(1, Math.sqrt((1920 * 1080) / Math.max(1, width * height)));
    const count = Math.max(7, Math.round(11 * density));

    clouds = Array.from({ length: count }, (_, index) => {
        const color = palette[index % palette.length];
        const key = color.join(",");
        return {
            x: Math.random() * width,
            y: Math.random() * height,
            radius: Math.max(width, height) * (0.14 + Math.random() * 0.20),
            phase: Math.random() * Math.PI * 2,
            speed: 0.001 + Math.random() * 0.002,
            driftX: -0.07 + Math.random() * 0.14,
            driftY: -0.05 + Math.random() * 0.10,
            sprite: cloudSprites.get(key),
            alpha: 0.065 + Math.random() * 0.09
        };
    });
}

function createStars() {
    const density = Math.min(1, Math.sqrt((1920 * 1080) / Math.max(1, width * height)));
    const count = Math.max(70, Math.round(150 * density));

    stars = Array.from({ length: count }, () => ({
        x: Math.random() * width,
        y: Math.random() * height,
        vx: -0.045 + Math.random() * 0.09,
        vy: -0.03 + Math.random() * 0.06,
        size: 0.5 + Math.random() * 1.4,
        phase: Math.random() * Math.PI * 2,
        twinkle: 0.006 + Math.random() * 0.014,
        hue: 190 + Math.random() * 90
    }));
}

function setMouse(x, y) {
    mouse.tx = x;
    mouse.ty = y;
    mouse.active = 1;
}

window.addEventListener("resize", resize);
window.addEventListener("mousemove", (event) => setMouse(event.clientX, event.clientY));
window.addEventListener("mouseleave", () => {
    mouse.active = 0;
});

function drawBackground() {
    if (backgroundCanvas) {
        ctx.drawImage(backgroundCanvas, 0, 0, width, height);
        return;
    }

    ctx.fillStyle = "#020107";
    ctx.fillRect(0, 0, width, height);
}

function drawClouds() {
    ctx.save();
    ctx.globalCompositeOperation = "lighter";

    for (const cloud of clouds) {
        cloud.x += cloud.driftX + Math.sin(time * cloud.speed + cloud.phase) * 0.12;
        cloud.y += cloud.driftY + Math.cos(time * cloud.speed + cloud.phase) * 0.08;

        if (cloud.x < -cloud.radius) cloud.x = width + cloud.radius;
        if (cloud.x > width + cloud.radius) cloud.x = -cloud.radius;
        if (cloud.y < -cloud.radius) cloud.y = height + cloud.radius;
        if (cloud.y > height + cloud.radius) cloud.y = -cloud.radius;

        const dx = cloud.x - mouse.x;
        const dy = cloud.y - mouse.y;
        const pullRadius = cloud.radius * 1.05;
        const dist = Math.hypot(dx, dy);
        const pull = dist < pullRadius ? (1 - dist / pullRadius) * mouse.active : 0;
        const x = cloud.x + dx * -0.022 * pull;
        const y = cloud.y + dy * -0.022 * pull;
        const radius = cloud.radius * (1 + pull * 0.12);

        ctx.globalAlpha = Math.min(0.22, cloud.alpha + pull * 0.045);
        ctx.drawImage(cloud.sprite, x - radius, y - radius, radius * 2, radius * 2);
    }

    ctx.globalAlpha = 1;
    ctx.restore();
}

function drawStars() {
    ctx.save();
    ctx.globalCompositeOperation = "lighter";

    mouse.x += (mouse.tx - mouse.x) * 0.07;
    mouse.y += (mouse.ty - mouse.y) * 0.07;
    mouse.active *= 0.987;

    const mouseRadius = 210;

    for (let i = 0; i < stars.length; i += 1) {
        const star = stars[i];
        const dx = mouse.x - star.x;
        const dy = mouse.y - star.y;
        const distance = Math.hypot(dx, dy) || 1;
        let force = 0;

        if (distance < mouseRadius) {
            force = (1 - distance / mouseRadius) * mouse.active;
            star.vx += (dx / distance) * force * 0.007;
            star.vy += (dy / distance) * force * 0.007;
        }

        star.vx *= 0.993;
        star.vy *= 0.993;
        star.vx = Math.max(-1.2, Math.min(1.2, star.vx));
        star.vy = Math.max(-1.2, Math.min(1.2, star.vy));
        star.x += star.vx;
        star.y += star.vy;

        if (star.x < -8) star.x = width + 8;
        if (star.x > width + 8) star.x = -8;
        if (star.y < -8) star.y = height + 8;
        if (star.y > height + 8) star.y = -8;

        const twinkle = 0.45 + 0.55 * Math.sin(time * star.twinkle + star.phase);
        const alpha = 0.24 + twinkle * 0.38 + force * 0.48;
        ctx.fillStyle = `hsla(${star.hue}, 95%, ${72 + force * 14}%, ${Math.min(1, alpha)})`;

        if (force > 0.05) {
            ctx.beginPath();
            ctx.arc(star.x, star.y, star.size + force * 1.4, 0, Math.PI * 2);
            ctx.fill();
        } else {
            ctx.fillRect(star.x, star.y, star.size, star.size);
        }
    }

    if (mouse.active > 0.02) {
        const glow = ctx.createRadialGradient(mouse.x, mouse.y, 0, mouse.x, mouse.y, 200);
        glow.addColorStop(0, `rgba(190, 230, 255, ${0.07 * mouse.active})`);
        glow.addColorStop(1, "rgba(0, 0, 0, 0)");
        ctx.fillStyle = glow;
        ctx.fillRect(0, 0, width, height);
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
    drawClouds();
    drawStars();
    requestAnimationFrame(render);
}

resize();
requestAnimationFrame(render);
