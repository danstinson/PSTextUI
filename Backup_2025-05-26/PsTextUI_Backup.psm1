#*****************************************************************************
# PsTextUI.pms1
# Draw user interface elements on a standard console terminal.
# 2025-02-02 Dan Stinson
#*****************************************************************************
# Important Concepts:
# -------------------
# The Screen Buffer is an array of characters and color data for output.  Its
# size can be much larger than the visible display.
# The Console Window is the visible display portion of the Screen Buffer.
# When setting the cursor position in the Screen Buffer, the Console Window
# will move to keep the cursor visible.
# Links:
#    PSHostRawUserInterface Class
#       https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.host.pshostrawuserinterface?view=powershellsdk-7.4.0
#    Console Screen Buffers
#       https://learn.microsoft.com/en-us/windows/console/console-screen-buffers
#*****************************************************************************

# Globals
# -------
$moduleName = $MyInvocation.MyCommand.Name
$moduleVersion = "1.0"
$debugFlag = $true
$debugFile = "C:\Temp\PsTextUI\debug.log"
$separatorAsterix = [string]::New("*", 80)
$separatorDash = [string]::New("-", 80)


enum TextJustifyValues
{
    Left
    Center
    Right
}

enum TitleStyles
{
    TopLine
    Underline
    SubBox
}

enum HorizontalAlignValues
{
    Left
    Center
    Right
}

enum VerticalAlignValues
{
    Top
    Middle
    Bottom
}

# Drawing line character sets
enum LineStyles
{
   Light
   Heavy
   Double
   Round
}

$lineStyleCharsLight = @([string][char]0x250C, # Top Corner Left
                         [string][char]0x2510, # Top Corner Right
                         [string][char]0x2514, # Bottom Corner Left
                         [string][char]0x2518, # Bottom Corner Right
                         [string][char]0x2500, # Horizontal
                         [string][char]0x2502, # Vertical
                         [string][char]0x251C, # Tee Left
                         [string][char]0x2524, # Tee Right
                         [string][char]0x2591) # Shadow

$lineStyleCharsHeavy = @([string][char]0x250F, # Top Corner Left
                         [string][char]0x2513, # Top Corner Right
                         [string][char]0x2517, # Bottom Corner Left
                         [string][char]0x251B, # Bottom Corner Right
                         [string][char]0x2501, # Horizontal
                         [string][char]0x2503, # Vertical
                         [string][char]0x2523, # Tee Left
                         [string][char]0x252B, # Tee Right
                         [string][char]0x2591) # Shadow

$lineStyleCharsDouble = @([string][char]0x2554, # Top Corner Left
                          [string][char]0x2557, # Top Corner Right
                          [string][char]0x255A, # Bottom Corner Left
                          [string][char]0x255D, # Bottom Corner Right
                          [string][char]0x2550, # Horizontal
                          [string][char]0x2551, # Vertical
                          [string][char]0x2560, # Tee Left
                          [string][char]0x2563, # Tee Right
                          [string][char]0x2591) # Shadow

# Round corners are only available with the single line char set.
$lineStyleCharsRound = @([string][char]0x256D, # Top Corner Left
                         [string][char]0x256E, # Top Corner Right
                         [string][char]0x2570, # Bottom Corner Left
                         [string][char]0x256F, # Bottom Corner Right
                         [string][char]0x2500, # Horizontal
                         [string][char]0x2502, # Vertical
                         [string][char]0x251C, # Tee Left
                         [string][char]0x2524, # Tee Right
                         [string][char]0x2591) # Shadow


#-----------------------------------------------------------------------------
function Show-Box
{
    # Draw Basic Box Shape
    # Parameters:
    #   - X, Y
    #       X and Y are zero-based absolute cursor positions in the VISIBLE
    #       portion of the Screen Buffer, i.e. the Console Window.  X is
    #       column, Y is row.  These coordinates determine the box's top left
    #       corner, which is the starting position of drawing the box.
    #       If X is not supplied, defaults to 0.
    #       If Y is not supplied, defaults to 0.
    #       X and Y are limited to visible window positions.
	#       If not supplied, X defaults to 0, Y defaults to next line.
    #   - Width, Height
    #       Box width and height.  The total box size is limited to the visible
    #       console window size.  Box X+Width and Y+Height must fit within
    #       the console window.
    #   - ForegroundColor, BackgroundColor
    #       ForegroundColor is line color, BackgroundColor is box color.
    #       Valid color names are: Black, DarkBlue, DarkGreen, DarkCyan,
    #       DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green,
    #       Cyan, Red, Magenta, Yellow, White
    #   - LineStyle
    #       Determines which line characters to draw
    #   - Shadow
    #       If present, draws a box shadow
    #   - SaveCursorLocation
    #       If present, the cursor will be returned to the position it was in
    #       when the function was called.  Otherwise, it will be the first position
	#       on the next line.

    param ([int]$X = 0,
           [int]$Y = $Host.UI.RawUI.CursorPosition.Y,
           [int]$Width = 20,
           [int]$Height = 10,
           [string]$ForegroundColor = ([Console]::ForegroundColor).ToString(),
           [string]$BackgroundColor = ([Console]::BackgroundColor).ToString(),
           [LineStyles]$LineStyle = ([LineStyles]::Light),
           [switch]$Shadow,
           [switch]$SaveCursorLocation)

    try
    {
        Debug $separatorDash
        Debug "Begin function: Show-Box"
        Debug "Parameters:"
        Debug "    X=$X"
        Debug "    Y=$Y"
        Debug "    Width=$Width"
        Debug "    Height=$Height"
        Debug "    ForegroundColor=$ForegroundColor"
        Debug "    BackgroundColor=$BackgroundColor"
        Debug "    LineStyle=$LineStyle"
        Debug "    Shadow=$Shadow"
        Debug "    SaveCursorLocation=$SaveCursorLocation"

        Debug "Host.UI.RawUI.BufferSize=$($Host.UI.RawUI.BufferSize)"    # Screen Buffer
        Debug "Host.UI.RawUI.WindowSize=$($Host.UI.RawUI.WindowSize)"    # Console Window
        Debug "Host.UI.RawUI.WindowPosition=$($Host.UI.RawUI.WindowPosition)"  # Console Window Position in Screen Buffer
        Debug "Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"


        Debug "Saving the current cursor position and colors in case we need to set them back when done ..."
        $saveCurPos = $Host.UI.RawUI.CursorPosition
        $saveFgColor = [Console]::ForegroundColor
        $saveBgColor = [Console]::BackgroundColor
        Debug "Saved cursorPosition: saveCurPos.X=$($saveCurPos.X) , saveCurPos.Y=$($saveCurPos.Y) "
        Debug "Saved colors: saveFgColor=$saveFgColor , saveBgColor=$saveBgColor "

        $Host.UI.RawUI.ForegroundColor = $ForegroundColor
        $Host.UI.RawUI.BackgroundColor = $BackgroundColor
        Debug "New colors: ForegroundColor=$([Console]::ForegroundColor) , BackgroundColor=$([Console]::BackgroundColor)"


        Debug "Bounds Checking ..."
        if ($X -lt 0)
        {
            throw "Show-Box: Parameter is out of bounds.  X=$X.  X cannot be less than 0."
        }
        if ($Width -lt 3)
        {
            throw "Show-Box: Parameter is out of bounds.  Width=$Width.  Width cannot be less than 3."
        }
        if (($X + $Width) -gt $Host.UI.RawUI.WindowSize.Width)
        {
            throw "Show-Box: Parameters are out of bounds.  (X=$X) + (Width=$Width) = $($X+$Width).  X + Width cannot be greater than right column of the console window ($($Host.UI.RawUI.WindowSize.Width))."
        }

        if ($Y -lt 0)
        {
            throw "Show-Box: Parameter is out of bounds.  Y=$Y.  Y cannot be less than 0."
        }
        if ($Height -lt 3)
        {
            throw "Show-Box: Parameter is out of bounds.  Height=$Height.  Height cannot be less than 3."
        }
        if (($Y + $Height) -gt $Host.UI.RawUI.WindowSize.Height)
        {
            throw "Show-Box: Parameters are out of bounds.   (Y=$Y) + (Height=$Height) = $($Y+$Height).  Y + Height cannot be greater than the bottom row of the console window ($($Host.UI.RawUI.WindowSize.Height))."
        }
        
    
        switch ($LineStyle)
        {
            ([LineStyles]::Light)  { $lineChars = $lineStyleCharsLight }
            ([LineStyles]::Heavy)  { $lineChars = $lineStyleCharsHeavy }
            ([LineStyles]::Double) { $lineChars = $lineStyleCharsDouble }
            ([LineStyles]::Round)  { $lineChars = $lineStyleCharsRound }
            default                { $lineChars = $lineStyleCharsLight }
        }

        $output = ""
        foreach ($c in $lineChars) { $output += (([int][char]$c).ToString() + ",") }
        Debug "lineChars(Unicode)=$output"

        $boxTopLeft     = $lineChars[0]
        $boxTopRight    = $lineChars[1]
        $boxBottomLeft  = $lineChars[2]
        $boxBottomRight = $lineChars[3]
        $boxHorizontal  = $lineChars[4]
        $boxVertical    = $lineChars[5]
        #$boxTeeLeft     = $lineChars[6] # Not used for basic box.
        #$boxTeeRight    = $lineChars[7] # Not used for basic box.
        $boxShadow      = $lineChars[8]


        # This line necessary when using [Console]::Write() with unicode characters.
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

        Debug "Drawing box top line ..."
        $Host.UI.RawUI.CursorPosition = @{ x = $X; y = $Y }
        Debug "    Starting position: Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"
        
        $charsOut = $boxTopLeft
        $charsOut += [string]::New($boxHorizontal, $width-2)
        $charsOut += $boxTopRight
        Debug "    charsOut.Length=$($charsOut.Length)"
        [Console]::Write($charsOut)


        Debug "Drawing box middle lines ..."
        $midLines = $Height-2
        Debug "    midLines=$midLines"

        for ($midLineNbr = 1; $midLineNbr -le $midLines; $midLineNbr++)
        {
            Debug "    midLineNbr=$midLineNbr"
            $Host.UI.RawUI.CursorPosition = @{ x = $X; y = ($Y + $midLineNbr) }
            Debug "        Starting position: Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"

            $charsOut = $boxVertical
            $charsOut += [string]::New(' ', $width-2)
            $charsOut += $boxVertical
            Debug "        charsOut.Length=$($charsOut.Length)"
            [Console]::Write($charsOut)

            # We didn't bounds check above for shadow.  If box is too wide, simply don't draw shadow.
            if (($Shadow) -And
                (($X + $charsOut.Length) -lt $Host.UI.RawUI.WindowSize.Width))
            {
                Debug "        Drawing shadow char."
                $Host.UI.RawUI.ForegroundColor = "DarkGray"
                $Host.UI.RawUI.BackgroundColor = "BlacK"
                [Console]::Write($boxShadow)
                $Host.UI.RawUI.ForegroundColor = $ForegroundColor
                $Host.UI.RawUI.BackgroundColor = $BackgroundColor
            }
        }


        Debug "Drawing box bottom line ..."
        $Host.UI.RawUI.CursorPosition = @{ x = $X; y = ($Y + ($Height - 1)) }
        Debug "    Starting position: Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"

        $charsOut = $boxBottomLeft
        $charsOut += [string]::New($boxHorizontal, $width-2)
        $charsOut += $boxBottomRight
        Debug "    charsOut.Length=$($charsOut.Length)"
        [Console]::Write($charsOut)

        # We didn't bounds check above for shadow.  If box is too wide, simply don't draw shadow.
        if (($Shadow) -And
            (($X + $charsOut.Length) -lt $Host.UI.RawUI.WindowSize.Width))
        {
            Debug "    Drawing shadow char."
            $Host.UI.RawUI.ForegroundColor = "DarkGray"
            $Host.UI.RawUI.BackgroundColor = "BlacK"
            [Console]::Write($boxShadow)
            $Host.UI.RawUI.ForegroundColor = $ForegroundColor
            $Host.UI.RawUI.BackgroundColor = $BackgroundColor
        }


        # We didn't bounds check above for shadow.  If box is too tall, simply don't draw shadow line.
        if (($Shadow) -And
            (($Y + $Height) -lt $Host.UI.RawUI.WindowSize.Height))
        {
            $Host.UI.RawUI.CursorPosition = @{ x = $X + 1; y = ($Y + ($Height)) }
            Debug "    Starting position: Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"

            $charsOut = [string]::New($boxShadow, $width)
            Debug "    charsOut.Length=$($charsOut.Length)"

            if (($X + 1 + $charsOut.Length) -gt $Host.UI.RawUI.WindowSize.Width)
            {
                $charsOut = $charsOut.Substring(0, $Host.UI.RawUI.WindowSize.Width - ($X + 1))
            }
            $Host.UI.RawUI.ForegroundColor = "DarkGray"
            $Host.UI.RawUI.BackgroundColor = "BlacK"
            [Console]::Write($charsOut)
            $Host.UI.RawUI.ForegroundColor = $ForegroundColor
            $Host.UI.RawUI.BackgroundColor = $BackgroundColor
        }


        Debug "Setting cursor position and colors back ..."
        if ($SaveCursorLocation)
        {
            $Host.UI.RawUI.CursorPosition = @{ x = $saveCurPos.X; y = $saveCurPos.Y }
            Debug "Restored cursorPosition: Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"
        }
		else
		{
			[Console]::Write("`r`n")
		}
        $Host.UI.RawUI.ForegroundColor = $saveFgColor
        $Host.UI.RawUI.BackgroundColor = $saveBgColor
        Debug "Restored colors: Host.UI.RawUI.ForegroundColor=$($Host.UI.RawUI.ForegroundColor) , Host.UI.RawUI.BackgroundColor=$($Host.UI.RawUI.BackgroundColor)"


        Debug "End function: Show-Box"
        Debug $separatorDash
    }
    catch
    {
        Debug "Show-Box: Exception occurred"
        Debug $_
        $Host.UI.RawUI.ForegroundColor = $saveFgColor
        $Host.UI.RawUI.BackgroundColor = $saveBgColor
        throw $_.Exception
    }
}


#-----------------------------------------------------------------------------
function Show-Text
{
    # Draw Text at X,Y location
    # Parameters:
    #   - Text
    #       Required.  The string message to draw.
    #   - X, Y
    #       X and Y are zero-based absolute cursor positions in the VISIBLE
    #       portion of the Screen Buffer, i.e. the Console Window.  X is
    #       column, Y is row.
    #       If X is not supplied, defaults to 0.
    #       If Y is not supplied, defaults to next line.
    #       X + Text.Length cannot go past the right side of the console window.
    #   - ForegroundColor, BackgroundColor
    #       Valid color names are: Black, DarkBlue, DarkGreen, DarkCyan,
    #       DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green,
    #       Cyan, Red, Magenta, Yellow, White
    #   - SaveCursorLocation
    #       If present, the cursor will be returned to the position it was in
    #       when the function was called.  Otherwise, it will remain after the
    #       last drawn character.


    param ([string]$Text,
           [int]$X = 0,
           [int]$Y = $Host.UI.RawUI.CursorPosition.Y,
           [string]$ForegroundColor = ([Console]::ForegroundColor).ToString(),
           [string]$BackgroundColor = ([Console]::BackgroundColor).ToString(),
           [switch]$SaveCursorLocation)

    try
    {
        Debug $separatorDash
        Debug "Begin function: Show-Text"
        Debug "Parameters:"
        Debug "    X=$X"
        Debug "    Y=$Y"
        Debug "    ForegroundColor=$ForegroundColor"
        Debug "    BackgroundColor=$BackgroundColor"
        Debug "    SaveCursorLocation=$SaveCursorLocation"

        Debug "Host.UI.RawUI.BufferSize=$($Host.UI.RawUI.BufferSize)"    # Screen Buffer
        Debug "Host.UI.RawUI.WindowSize=$($Host.UI.RawUI.WindowSize)"    # Console Window
        Debug "Host.UI.RawUI.WindowPosition=$($Host.UI.RawUI.WindowPosition)"  # Console Window Position in Screen Buffer
        Debug "Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"


        Debug "Saving the current cursor position and colors in case we need to set them back when done ..."
        $saveCurPos = $Host.UI.RawUI.CursorPosition
        $saveFgColor = [Console]::ForegroundColor
        $saveBgColor = [Console]::BackgroundColor
        Debug "Saved cursorPosition: saveCurPos.X=$($saveCurPos.X) , saveCurPos.Y=$($saveCurPos.Y) "
        Debug "Saved colors: saveFgColor=$saveFgColor , saveBgColor=$saveBgColor "

        $Host.UI.RawUI.ForegroundColor = $ForegroundColor
        $Host.UI.RawUI.BackgroundColor = $BackgroundColor
        Debug "New colors: ForegroundColor=$([Console]::ForegroundColor) , BackgroundColor=$([Console]::BackgroundColor)"


        if ([string]::IsNullOrEmpty($Text)) { throw "Show-Text: Parameter Text is required." }

        Debug "Bounds Checking ..."
        if ($X -lt 0)
        {
            throw "Show-Text: Parameter is out of bounds.  X=$X.  X cannot be less than zero."
        }
        if (($X + $Text.Length) -gt $Host.UI.RawUI.WindowSize.Width)
        {
            throw "Show-Text: Parameters are out of bounds.  (X=$X) + (Text.Length=$($Text.Length)) = $($X+$Text.Length).  X + Text.Length cannot be greater than right column of the console window ($($Host.UI.RawUI.WindowSize.Width))."
        }
        if ($Y -lt 0)
        {
            throw "Show-Text: Parameter is out of bounds.  Y=$Y.  Y cannot be less than zero."
        }
        if ($Y -ge $Host.UI.RawUI.WindowSize.Height)
        {
            throw "Show-Text: Parameter is out of bounds.  Y=$Y.  Y must be less than the bottom row of the console window ($($Host.UI.RawUI.WindowSize.Height))."
        }


        # This line necessary when using [Console]::Write() with unicode characters.
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

        Debug "Drawing text ..."
        $Host.UI.RawUI.CursorPosition = @{ x = $X; y = $Y }
        Debug "    Starting position: Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"
        
        $charsOut = $Text
        Debug "    charsOut.Length=$($charsOut.Length)"
        [Console]::Write($charsOut)

        Debug "Setting cursor position and colors back ..."
        if ($SaveCursorLocation)
        {
            $Host.UI.RawUI.CursorPosition = @{ x = $saveCurPos.X; y = $saveCurPos.Y }
            Debug "Restored cursorPosition: Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"
        }
        $Host.UI.RawUI.ForegroundColor = $saveFgColor
        $Host.UI.RawUI.BackgroundColor = $saveBgColor
        Debug "Restored colors: Host.UI.RawUI.ForegroundColor=$($Host.UI.RawUI.ForegroundColor) , Host.UI.RawUI.BackgroundColor=$($Host.UI.RawUI.BackgroundColor)"


        Debug "End function: Show-Text"
        Debug $separatorDash
    }
    catch
    {
        Debug "Show-Text: Exception occurred"
        Debug $_
        $Host.UI.RawUI.ForegroundColor = $saveFgColor
        $Host.UI.RawUI.BackgroundColor = $saveBgColor
        throw $_.Exception
    }
}


#-----------------------------------------------------------------------------
function Show-TextBox
{
    # Draw Box with Text inside
    # Parameters:
    #   - Text
    #       Required.  The string text message to draw.
    #       If text contains CR or LF characters, it is split into multiple
    #       lines of text.
    #   - Justify
    #       Text inside the box will be justified as Left, Center, or Right.
    #       Default is Center.
    #   - HorizontalAlign
    #       Box will be aligned horizontally as Left, Center, or Right.
    #       Default is Center.
    #   - VerticalAlign
    #       Box will be aligned vertically as Top, Middle, or Bottom.
    #       Default is Middle.
    #   - X, Y
    #       Used the same as Show-Box function.
    #       If X is specified, then HorizontalAlign is ignored.
    #       If Y is specified, then VerticalAlign is ignored.
    #   - Width, Height
    #       Used the same as Show-Box function.
    #       If Width is specified, then it sets box width.  Otherwise width
    #       will be auto-sized based on Text length.
    #       If Height is specified, then it sets box height.  Otherwise height
    #       will be auto-sized based on number of Text lines.
    #   - TextColor
    #       Color of the Text.
    #   - ForegroundColor, BackgroundColor
    #       Used the same as Show-Box function.
    #   - LineStyle
    #       Used the same as Show-Box function.
    #   - Shadow
    #       Used the same as Show-Box function.
    #   - SaveCursorLocation
    #       Used the same as Show-Box function.
    #   - TitleText
    #       Draw this text as a title on the box.
    #   - TitleColor
    #       Color of the TitleText.  Default is TextColor.
    #   - TitleBackgroundColor
    #       Background color of the TitleText.  Default is BackgroundColor.
    #   - TitleStyle
    #       Maybe TopLine, Underline, or SubBox.
    #       If TopLine, the title is drawn over the top line of the box.
    #       If Underline, the title is drawn in the first row inside the box
    #       and is underlined.
    #       If SubBox, the title is drawn in an inner box inside the main box
    #       and inner box colors are inverted.
    #   - TitleJustify
    #       TitleText will be justified as Left, Center, or Right.
    #       Default is Center.
    #   - PadWidth, PadHeight
    #       The number of spaces or lines between text and inside of box.

    param ([string]$Text,
           [TextJustifyValues]$Justify = ([TextJustifyValues]::Left).ToString(),
           [HorizontalAlignValues]$HorizontalAlign = ([HorizontalAlignValues]::Center).ToString(),
           [VerticalAlignValues]$VerticalAlign = ([VerticalAlignValues]::Middle).ToString(),
           [int]$X = -1,
           [int]$Y = -1,
           [int]$Width = -1,
           [int]$Height = -1,
           [string]$TextColor = ([Console]::ForegroundColor).ToString(),
           [string]$ForegroundColor = ([Console]::ForegroundColor).ToString(),
           [string]$BackgroundColor = ([Console]::BackgroundColor).ToString(),
           [LineStyles]$LineStyle = ([LineStyles]::Light),
           [switch]$Shadow,
           [switch]$SaveCursorLocation,
           [string]$TitleText,
           [string]$TitleColor = $TextColor,
           [string]$TitleBackgroundColor = $BackgroundColor,
           [TitleStyles]$TitleStyle = ([TitleStyles]::TopLine).ToString(),
           [TextJustifyValues]$TitleJustify = ([TextJustifyValues]::Left).ToString(),
           [int]$PadWidth = 1,
           [int]$PadHeight = 0)

    try
    {
        Debug $separatorDash
        Debug "Begin function: Show-TextBox"
        Debug "Parameters:"
        Debug "    Text=$Text"
        Debug "    Justify=$Justify"
        Debug "    HorizontalAlign=$HorizontalAlign"
        Debug "    VerticalAlign=$VerticalAlign"
        Debug "    X=$X"
        Debug "    Y=$Y"
        Debug "    Width=$Width"
        Debug "    Height=$Height"
        Debug "    TextColor=$TextColor"
        Debug "    ForegroundColor=$ForegroundColor"
        Debug "    BackgroundColor=$BackgroundColor"
        Debug "    LineStyle=$LineStyle"
        Debug "    Shadow=$Shadow"
        Debug "    SaveCursorLocation=$SaveCursorLocation"
        Debug "    TitleText=$TitleText"
        Debug "    TitleColor=$TitleColor"
        Debug "    TitleBackgroundColor=$TitleBackgroundColor"
        Debug "    TitleStyle=$TitleStyle"
        Debug "    TitleJustify=$TitleJustify"


        Debug "Host.UI.RawUI.BufferSize=$($Host.UI.RawUI.BufferSize)"    # Screen Buffer
        Debug "Host.UI.RawUI.WindowSize=$($Host.UI.RawUI.WindowSize)"    # Console Window
        Debug "Host.UI.RawUI.WindowPosition=$($Host.UI.RawUI.WindowPosition)"  # Console Window Position in Screen Buffer
        Debug "Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"


        Debug "Saving the current cursor position and colors in case we need to set them back when done ..."
        $saveCurPos = $Host.UI.RawUI.CursorPosition
        $saveFgColor = [Console]::ForegroundColor
        $saveBgColor = [Console]::BackgroundColor
        Debug "Saved cursorPosition: saveCurPos.X=$($saveCurPos.X) , saveCurPos.Y=$($saveCurPos.Y) "
        Debug "Saved colors: saveFgColor=$saveFgColor , saveBgColor=$saveBgColor "


        Debug "Converting parameter Text to an array of lines ..."
        $textLines = $Text.Replace("`r`n", "`n").Replace("`r", "`n").Split("`n")
        Debug "textLines.Count=$($textLines.Count)"
        Debug "textLines=$textLines"


        Debug "Determining box size ..."

        Debug "Finding the maximum allowed box width ..."
        if ($X -ge 0)
        {
            Debug "    X is specified so the maximum allowed box width is (Host.UI.RawUI.WindowSize.Width - X)"
            $maxAllowedBoxWidth = $Host.UI.RawUI.WindowSize.Width - $X
        }
        else
        {
            Debug "    X is not specified so the maximum allowed box width is Host.UI.RawUI.WindowSize.Width"
            $maxAllowedBoxWidth = $Host.UI.RawUI.WindowSize.Width
        }
        Debug "    maxAllowedBoxWidth=$maxAllowedBoxWidth"

        Debug "Finding the maximum allowed box height ..."
        if ($Y -ge 0)
        {
            Debug "    Y is specified so the maximum allowed box height is (Host.UI.RawUI.WindowSize.Height - Y)"
            $maxAllowedBoxHeight = $Host.UI.RawUI.WindowSize.Height - $Y
        }
        else
        {
            Debug "    Y is not specified so the maximum allowed box height is Host.UI.RawUI.WindowSize.Height"
            $maxAllowedBoxHeight = $Host.UI.RawUI.WindowSize.Height
        }
        Debug "    maxAllowedBoxHeight=$maxAllowedBoxHeight"


        Debug "Finding box width ..."
        if ($Width -ge 3)
        {
            Debug "    Width is specified, and is >= 3, so using fixed width."
            $boxWidth = $Width
        }
        else
        {
            Debug "    Width is not specified so using max length of text lines to determine width."
            $maxLineLength = 0
            foreach ($line in $textLines)
            {
                Debug "        line=$line"
                Debug "            line.Length=$($line.Length)"
                if ($line.Length -gt $maxLineLength) { $maxLineLength = $line.Length}
                Debug "        maxLineLength=$maxLineLength"
            }
            Debug "    boxWidth is maxLineLength + 2 line characters + (PadWidth * 2)"
            $boxWidth = $maxLineLength + 2 + ($PadWidth * 2)
        }
        Debug "    boxWidth=$boxWidth"

        if ($boxWidth -gt $maxAllowedBoxWidth)
        {
            Debug "    boxWidth is greater than maxAllowedBoxWidth.  Forcing boxWidth to maxAllowedBoxWidth."
            $boxWidth = $maxAllowedBoxWidth
            Debug "    boxWidth=$boxWidth"
        }
        

        Debug "Finding box height ..."
        if ($Height -ge 3)
        {
            Debug "    Height is specified, and is >= 3, so using fixed height."
            $boxHeight = $Height
        }
        else
        {
            Debug "    Height is not specified so using count of text lines to determine height."
            Debug "    boxHeight is Text lines count + 2 line characters + (PadHeight * 2)"
            $boxHeight = $textLines.Count + 2 + ($PadHeight * 2)
        }
        Debug "    boxHeight=$boxHeight"

        if ($boxHeight -gt $maxAllowedBoxHeight)
        {
            Debug "    boxHeight is greater than maxAllowedBoxHeight.  Forcing boxHeight to maxAllowedBoxHeight."
            $boxHeight = $maxAllowedBoxHeight
            Debug "    boxHeight=$boxHeight"
        }


        Debug "Finding box X ..."
        if ($X -ge 0)
        {
            Debug "    X is specified so using that."
            $boxX = $X
        }
        else
        {
            Debug "    X is not specified so calculating by HorizontalAlign (HorizontalAlign=$HorizontalAlign)."
            switch ($HorizontalAlign.ToString())
            {
               "Left"   { $boxX = 0 }
               "Center" { $boxX = [int](($($Host.UI.RawUI.WindowSize).Width - $boxWidth) / 2) }
               "Right"  { $boxX = [int]($($Host.UI.RawUI.WindowSize).Width - $boxWidth) }
           }
        }
        Debug "    boxX=$boxX"
        

        Debug "Finding box Y ..."
        if ($Y -ge 0)
        {
            Debug "    Y is specified so using that."
            $boxY = $Y
        }
        else
        {
            Debug "    Y is not specified so calculating by VerticalAlign (VerticalAlign=$VerticalAlign)."
            switch ($VerticalAlign.ToString())
            {
               "Top"    { $boxY = 0 }
               "Middle" { $boxY = [int](($($Host.UI.RawUI.WindowSize).Height - $boxHeight) / 2) }
               "Bottom" { $boxY = [int]($($Host.UI.RawUI.WindowSize).Height - $boxHeight) }
           }
        }
        Debug "    boxY=$boxY"


        Debug "Calling Show-Box ..."
        if ($Shadow)
        {
            Show-Box -X $boxX -Y $boxY -Width $boxWidth -Height $boxHeight `
                     -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor `
                     -LineStyle $LineStyle -Shadow
        }
        else
        {
            Show-Box -X $boxX -Y $boxY -Width $boxWidth -Height $boxHeight `
                     -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor `
                     -LineStyle $LineStyle
        }
  
        
        Debug "Processing text lines to draw inside box ..."
        Debug "    textLines.Count=$($textLines.Count)"
        for ($lineNbr = 1; $lineNbr -le $textLines.Count; $lineNbr++)
        {
            $line = $textLines[$lineNbr - 1] # arrays are zero-based.
            Debug "    lineNbr=$lineNbr, line=$line"
            if ($lineNbr -gt ($boxHeight - 2 - ($PadHeight * 2)))
            {
                Debug "    lineNbr is greater than (boxHeight - 2 - (PadHeight * 2)).  Not drawing."
            }
            else
            {
                if ($line.Length -gt ($boxWidth - 2 - ($PadWidth * 2)))
                {
                    Debug "    line.Length is greater than (boxWidth - 2 - (PadWidth * 2)).  Truncating line."
                    $line = $line.Substring(0, $boxWidth - 2 - ($PadWidth * 2))
                    Debug "    line=$line"
                }

                Debug "    Calling Show-Text ..."
                # Depending on placement of new lines characters, the text lines
                # array can have empty entries.  Show-Text requires a non-blank
                # value for -Text.  If the current $line is blank, pass a single
                # space.
                if ($line.Length -le 0)
                {
                    Debug "        Line value is blank.  Must pass at least one space to Show-Text."
                    $line = " "
                }
                Show-Text -Text $line -X ($boxX + 1 + $PadWidth) -Y ($boxY + 1 + $PadHeight + ($lineNbr - 1)) -SaveCursorLocation
            }
        }


        # Set cursor position and colors back.
        if ($SaveCursorLocation)
        {
            $Host.UI.RawUI.CursorPosition = @{ x = $saveCurPos.X; y = $saveCurPos.Y }
            Debug "Restored cursorPosition: Host.UI.RawUI.CursorPosition=$($Host.UI.RawUI.CursorPosition)"
        }
        $Host.UI.RawUI.ForegroundColor = $saveFgColor
        $Host.UI.RawUI.BackgroundColor = $saveBgColor
        Debug "Restored colors: Host.UI.RawUI.ForegroundColor=$($Host.UI.RawUI.ForegroundColor) , Host.UI.RawUI.BackgroundColor=$($Host.UI.RawUI.BackgroundColor)"




        Debug "End function: Show-TextBox"
        Debug $separatorDash
    }
    catch
    {
        Debug "Show-TextBox: Exception occurred"
        Debug $_
        $Host.UI.RawUI.ForegroundColor = $saveFgColor
        $Host.UI.RawUI.BackgroundColor = $saveBgColor
        throw $_.Exception
    }
}


#------------------------------------------------------------------------------
function Debug
{
    param ($debugMsg = "")
    
    if ($debugFlag -eq $true)
    {
        $debugDir = Split-Path -Parent $debugFile
        if ((Test-Path -Path $debugDir) -eq $false) { New-Item -ItemType Directory -Path $debugDir | Out-Null }
       
        $debugMsgOut = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - "
        if ($debugMsg.GetType().Name -eq "String") { $debugMsgOut += $debugMsg }
        else { $debugMsgOut += $($debugMsg | Out-String) }
        Add-Content -Path $debugFile -Value $debugMsgOut
    }
}


#-----------------------------------------------------------------------------
Debug $separatorAsterix
Debug "Module: $moduleName , Version: $moduleVersion"
Debug $separatorAsterix



#-----------------------------------------------------------------------------
Export-ModuleMember -Function Show-Box, Show-Text, Show-TextBox
#Export-ModuleMember -Variable * # Only use for debugging.
