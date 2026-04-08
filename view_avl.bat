@echo off
cd /d ""
echo.
echo  AVL geometry viewer loading...
echo  Interact with the graphics window normally.
echo  To close: Return (in graphics window) then Return then QUIT
echo.
(type "avl_pre.txt" ^& type CON) | "C:\Users\kaspe\OneDrive\Cornell\All\Coding\end-of-semester-25-26\avl352.exe" "dfo.avl"
