"""
Capture a consistent set of screenshots for documentation.
Requires: backend on :8080, `flutter run -d windows`, Products visible.

Install: pip install pyautogui
"""
from __future__ import annotations

import time
from pathlib import Path

import pyautogui

pyautogui.PAUSE = 0.35
pyautogui.FAILSAFE = True

OUT = Path(__file__).resolve().parent


def pick_flutter_window():
    wins = [
        w
        for w in pyautogui.getAllWindows()
        if w.title and "mobile_flutter" in w.title.lower() and w.width > 200 and w.height > 200
    ]
    if not wins:
        raise RuntimeError("No mobile_flutter window found.")
    return max(wins, key=lambda w: w.width * w.height)


def shot(name: str, win) -> None:
    win.activate()
    time.sleep(0.45)
    img = pyautogui.screenshot(region=(win.left, win.top, win.width, win.height))
    path = OUT / name
    img.save(path)
    print(f"Saved {path}")


def click_rel(win, rx: float, ry: float) -> None:
    pyautogui.click(int(win.left + win.width * rx), int(win.top + win.height * ry))


def try_pop(win) -> None:
    """Flutter AppBar leading back — try a short vertical sweep (DPI-safe-ish)."""
    win.activate()
    time.sleep(0.2)
    base_x = win.left + int(win.width * 0.02)
    for frac in (0.055, 0.065, 0.075, 0.085):
        pyautogui.click(base_x, int(win.top + win.height * frac))
        time.sleep(0.22)


def main() -> None:
    win = pick_flutter_window()

    shot("10-products-home.png", win)

    # View Allocation (second quick action)
    click_rel(win, 0.5, 0.34)
    time.sleep(0.9)
    shot("11-allocation.png", win)
    try_pop(win)
    time.sleep(0.6)
    shot("12-products-after-allocation.png", win)

    # Sell first visible product (mouse clicks are unreliable on Flutter Windows here;
    # keyboard focus + Enter opens the first product's sale screen reliably.)
    click_rel(win, 0.5, 0.25)
    time.sleep(0.2)
    for _ in range(35):
        pyautogui.press("tab")
        time.sleep(0.04)
    pyautogui.press("enter")
    time.sleep(0.9)
    shot("13-sale-form.png", win)
    try_pop(win)
    time.sleep(0.6)
    shot("14-products-after-sale.png", win)

    # Pending sales queue
    click_rel(win, 0.5, 0.42)
    time.sleep(0.9)
    shot("15-pending-sales.png", win)


if __name__ == "__main__":
    main()
