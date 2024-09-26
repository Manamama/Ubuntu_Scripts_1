setlocal enabledelayedexpansion

rem Get current date and time
echo %date% %time%
set SECONDS=0

echo You can use all the languages below or more:
tesseract --list-langs
echo Use : -l LANG[+LANG] to specify
echo.

set "pdf_path=%~1"
set "tmp_dir=%TEMP%\pdf_to_images"
set "output_dir=%~dp1"
set "base_name_filename=%~n1"
echo Output directory: %output_dir%

rem Display PDF info
for %%F in ("%pdf_path%") do (
    echo PDF info:
    file "%%F"
)

mkdir "%tmp_dir%"
pdftoppm -jpeg "%pdf_path%" "%tmp_dir%\page"

rem Count number of images created
set num_images=0
for %%I in ("%tmp_dir%\*.jpg") do (
    set /a num_images+=1
)
echo Number of temp images created: !num_images!
echo.

rem Process each image with tesseract
for %%I in ("%tmp_dir%\*.jpg") do (
    set "base_name=%%~nI"
    echo Processing via tesseract: %%I, with %2 %3 %4...
    tesseract "%%I" "%tmp_dir%\!base_name!" %2 %3 %4
)

rem Combine all text files into one
type "%tmp_dir%\*.txt" > "%output_dir%\%base_name_filename%.txt"
echo.

if exist "%output_dir%\%base_name_filename%.txt" (
    set /a SECONDS=!SECONDS! + 1
    echo Time taken to join text files: !SECONDS! seconds
    echo.
    echo Statistics - number of characters (wc -c) and filename:
    for %%F in ("%output_dir%\%base_name_filename%.txt") do (
        for /f %%A in ('find /c /v "" ^< "%%F"') do set char_count=%%A
        echo !char_count! characters in "%output_dir%\%base_name_filename%.txt"
    )
    echo Tokens (ttok): !ttok!
) else (
    echo Error: Final output file "%output_dir%\%base_name_filename%.txt" not found.
)

rd /s /q "%tmp_dir%"
endlocal
