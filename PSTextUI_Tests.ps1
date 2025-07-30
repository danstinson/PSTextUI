Import-Module ".\PSTextUI.psm1"

#$ErrorActionPreference = "Stop"

#Clear-Host

#Write-Host "Show-Box"
#Show-Box
#Write-Host "Show-Box -Shadow"
#Show-Box -Shadow
#Write-Host "Show-Box -X 30 -Y 0 -Shadow"
#how-Box -X 30 -Y 0 -Shadow
#Write-Host "Show-Box -X 20 -Y 30"
#Show-Box -X 20 -Y 30
#Write-Host "Show-Box -X 50 -Y 30 -Shadow"
#Show-Box -X 50 -Y 30 -Shadow
#Write-Host "Show-Box -X 100 -Y 10"
#Show-Box -X 100 -Y 10
#Write-Host "Show-Box -X 100 -Y 25 -Shadow"
#Show-Box -X 100 -Y 25 -Shadow
#Pause

#Show-Box -X 10 -Y 11 -ForegroundColor Cyan -BackgroundColor DarkBlue -Width 30 -Height 15
#Show-Box -X 30 -Y 14 -ForegroundColor Green -BackgroundColor DarkMagenta -LineStyle Round -Width 40 -Height 5 -Shadow
#Show-Box -X 45 -Y 21 -ForegroundColor Red -BackgroundColor Blue -Width 40 -Height 12 -Shadow
#Show-Box -X 45 -Y 21 -ForegroundColor Red -BackgroundColor Blue -Width 40 -Height 3 -LineStyle Double -SaveCursorLocation
#Pause

#Show-Text "Testing 1"
#Show-Text "Testing 2" -X 22 -Y 3 -BackgroundColor Red
#Show-Text "Testing 3" -X 47 -Y 5 -BackgroundColor Green
#Show-Text "Testing 4" -Y 1  -SaveCursorLocation
#Show-Text "This text barely fits." -X 98 -Y 39 -SaveCursorLocation
#Pause

Show-TextBox "This is a test."
#$text = @"
#Hello
#Line Two
#Line Two and a half that is the longest
#Line Two and three quarters that is verrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrry long!
#Line Three
#Line Four Longer
#"@
#Show-TextBox -Text $text
#pause
#Show-TextBox -Text $text -X 40 -Y 10 -SaveCursorLocation -Shadow
#pause


# Show-TextBox -Text "this`nis`n`n`na`ntest`nwith new lines back-to-back."
# pause

# $text = "# Test with big padding.`n"
# for ($i = 1; $i -lt 20; $i++)
# {
    # $text += ([string]::New("*", 80) + "`n")
# }
# Show-TextBox -Text $text -PadWidth 5 -PadHeight 5
# pause


#$text = "# Testing with massive text way outside bounds."
#for ($i = 1; $i -lt 200; $i++)
#{
#    $text += ([string]::New("*", 200) + "`n")
#}
#Show-TextBox -Text $text -Shadow
#pause

