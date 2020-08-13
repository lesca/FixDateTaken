<#
.Synopsis
   If "Date Taken" is missing from an image file, use "Date Create" to fill the "Date Taken" property. 
.Description
   1) This solution only works if the "Date Create" is correct. 
   2) This script only fix .jpeg and .jpg image files.
.Parameter Path
   The image folder path to process.
.Example
   . .\FixDateTake.ps1
   fixDateTake <ImageFolderPath>
.Outputs
   The scripcmdlet outputs FileInfo objects and check if "Date Taken" exisits, if yes, skip; if no, update the property with "Date Create". 
.Functionality
   Update "Date Taken" with "Date Create" for all .jpeg and .jpg images from a specified folder.
#>


# Reference
# https://github.com/ChrisWarwick/ExifDateTime/blob/master/ExifDateTime.psm1

# Add System.Drawing for [System.Drawing.Imaging.Metafile] type
Add-Type -AssemblyName 'System.Drawing'

function fixDateTaken($path) {
    Try {
        $files = Get-ChildItem $path | Where {$_.extension -like ".jpg" -or $_.extension -like ".jpeg"}
    }
    Catch {
        Write-Warning -Message "Check folder path $path"
        Write-Warning -Message "$_"
        Break
    }
    Foreach ($file in $files) {
        # Read the current file and extract the Exif DateTaken property
        $ImageFile = $file.FullName
        Write-Host -ForegroundColor Yellow "$ImageFile"

        
        # Parameters for FileStream: Open/Read/SequentialScan
        $FileStreamArgs = @(
            $ImageFile
            [System.IO.FileMode]::Open
            [System.IO.FileAccess]::Read
            [System.IO.FileShare]::Read
            1024,     # Buffer size
            [System.IO.FileOptions]::SequentialScan
        )

        Try {
            $FileStream = New-Object System.IO.FileStream -ArgumentList $FileStreamArgs
            $Img = [System.Drawing.Imaging.Metafile]::FromStream($FileStream)
            if ($Img.PropertyItems.Id.Contains(36867)) {
                $ExifDT = $Img.GetPropertyItem('36867')

                # Convert the raw Exif data to DateTime
                $ExifDtString = [System.Text.Encoding]::ASCII.GetString($ExifDT.Value)

                #Write-Host -ForegroundColor Green "Skip: Original Time is $($OldTime.ToString('F'))"
                Write-Host -ForegroundColor Green "Skip: Original Time is $($ExifDtString)"
                Continue 
            } else { # no taken date, use creation time
                $NewTime = $file.CreationTime
                
                # Convert to a string, changing slashes back to colons in the date.  Include trailing 0x00...
                $ExifTime = $NewTime.ToString("yyyy:MM:dd HH:mm:ss`0")
                Write-Host -ForegroundColor Green "Update: New Time is $ExifTime" 
                if ($ExifDT -eq $null) {
                    $ExifDT = $Img.PropertyItems[0]
                    $ExifDT.Id = 36867
                    $ExifDT.Len = 20
                    $ExifDT.Type = 2
                }
            }
        }
        Catch{
            Write-Warning -Message "Check $ImageFile is a valid image file ($_)"
            If ($Img) {$Img.Dispose()}
            If ($FileStream) {$FileStream.Close()}
            Break
        }

        Try {
            # Overwrite the EXIF DateTime property in the image and set
            $ExifDT.Value = [Byte[]][System.Text.Encoding]::ASCII.GetBytes($ExifTime)
            $Img.SetPropertyItem($ExifDT)
        }
        Catch{
            Write-Warning -Message "Check Exif data ($_)"
            If ($Img) {$Img.Dispose()}
            If ($FileStream) {$FileStream.Close()}
            Break
        }

        # Create a memory stream to save the modified image...
        $MemoryStream = New-Object System.IO.MemoryStream

        Try {
            # Save to the memory stream then close the original objects
            # Save as type $Img.RawFormat  (Usually [System.Drawing.Imaging.ImageFormat]::JPEG)
            $Img.Save($MemoryStream, $Img.RawFormat)
        }
        Catch {
            Write-Warning -Message "Problem modifying image $ImageFile ($_)"
            $MemoryStream.Close()
            $MemoryStream.Dispose()
            Break
        }
        Finally {
            $Img.Dispose()
            $FileStream.Close()
        }


        # Update the file (Open with Create mode will truncate the file)
        Try {
            $Writer = New-Object System.IO.FileStream($ImageFile, [System.IO.FileMode]::Create)
            $MemoryStream.WriteTo($Writer)
        }
        Catch {
            Write-Warning -Message "Problem saving to $OutFile ($_)"
            Break
        }
        Finally {
            If ($Writer) {$Writer.Flush(); $Writer.Close()}
            $MemoryStream.Close()
            $MemoryStream.Dispose()
        }

    } # End Foreach Path
}


echo ""
echo "Done"
#pause
