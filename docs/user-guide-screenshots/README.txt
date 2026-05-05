E-VAT Sales App — screenshots for user documentation
=====================================================

Location (repo): docs/user-guide-screenshots/

Recommended figures for your guide
------------------------------------
- 00-products-skia.png       — Products screen (Skia render; sharp for print/PDF)
- 10-products-home.png     — Products screen (full window incl. title bar)
- 11-allocation.png        — Downloaded allocation / remaining quantities
- 15-pending-sales.png     — Pending sync queue + Online mode + Sync button
- 20-sale-form-skia.png    — Sell / checkout screen (Skia render)
- 21-sale-form-window.png  — Same sale screen (full window)

How these were captured
-----------------------
1. Backend (Go) running on http://localhost:8080
2. `flutter run -d windows` from folder mobile_flutter
3. Window shots: Python + pyautogui (see capture_flow.py)
4. Skia shots: `flutter screenshot --type skia --vm-service-url=...` (URL from flutter run output)

To regenerate window shots
--------------------------
  pip install pyautogui
  python docs/user-guide-screenshots/capture_flow.py

To capture Skia shots after `flutter run`, copy the "Dart VM Service" URL from the terminal, then:
  flutter screenshot --type skia --vm-service-url "<URL>" -o docs/user-guide-screenshots/myshot.png

Optional: Sales History / Dashboard — open those screens in the running app, then run the same
flutter screenshot command while that route is visible.
