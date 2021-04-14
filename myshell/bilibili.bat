@echo off
chcp 65001
set n=0
for /f tokens^=8^ delims^=^" %%s in (info.json) do (
mkdir "%%s"
for /d %%d in (*) do (
for /f tokens^=8^ delims^=^" %%n in (%%d\info.json) do (
ffmpeg -i "%%d\video.m4s" -i "%%d\audio.m4s" -codec copy "%%s\%%n.mp4"
)
)
)