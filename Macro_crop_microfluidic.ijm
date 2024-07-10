// This macro aims to create substack of all bright regions within one large image
// All function used are available from the stable version of Fiji.

// Series one by one
// Loop through all files in a folder
// Crop on loading in the Z dimension (every 5 slices)

// Macro author R. De Mets
// Version : 0.2.2 , 27/03/2024

setBatchMode(true);
run("Close All");
IJ.freeMemory();
run("Collect Garbage");

thresholdValue = 1000;
XTop = newArray();
XBottom =  newArray();
BrightArea = 0;

// GUI
Dialog.create("Cropping tools");
Dialog.addDirectory("Select Folder to process","");
Dialog.addNumber("How many series ?", 3)
Dialog.addCheckbox("Save MIP ?", false);
Dialog.show();

dirS = Dialog.getString();
nSeries = Dialog.getNumber();
save_max = Dialog.getCheckbox();

pattern = ".*"; // for selecting all the files in the folder
filenames = getFileList(dirS);

for (file = 0; file < filenames.length; file++) {
	// Open file if CZI
		currFile = dirS+filenames[file];
		if(endsWith(currFile, ".czi") && matches(filenames[file], pattern)) { // process czi files matching regex

			title = substring(filenames[file],0,lengthOf(filenames[file])-4);;
			folderSave = dirS + File.separator + title;
			File.makeDirectory(folderSave);
			
			// Open the image with all series
			for (series = 1; series <= nSeries; series++) {
				//run("Bio-Formats Importer", "open=filename open_all_series windowless=true");
				seriestoopen="series_"+series;
				//print(seriestoopen);

				run("Bio-Formats Importer", "open=[" + currFile + "] specify_range z_step_"+series+"=5 series_"+series);
				//run("Bio-Formats Importer", "open=[" + currFile + "] specify_range z_begin_"+series+"=30 z_end_"+series+"=70 z_step_"+series+"=2 series_"+series);
				
				list = getList("image.titles");
				for (image_list = 0; image_list < list.length; image_list++) {
					window_title = list[image_list];
					selectWindow(window_title);
					getDimensions(width, height, channels, slices, frames);
					if (slices>5) { // If the series is a z-stack, to remove label image
						print(window_title);
						roiManager("reset");
						run("Z Project...", "projection=[Max Intensity]");
						run("Rotate 90 Degrees Left");
						run("Reslice [/]...", "output=6.000 start=Top avoid");
						run("Median...", "radius=10");
				
						for ( i = 0; i < height; i += 1) {
						//for ( i = 0; i < 24166; i += 1) {
							//print(getValue(i, 0));
							PixValue = getValue(i, 0);
							if (BrightArea == 0 ) { // If we are in a black area
								if (PixValue>thresholdValue) {
									XTop = Array.concat(XTop, i);
									BrightArea = 1; // We are in a white area
								}
							}
							if (BrightArea == 1 ) { // If we are in a black area
								if (PixValue<thresholdValue) {
									XBottom = Array.concat(XBottom, i);
									BrightArea = 0; // We are in a black area
								}
							}
						}
						//print(XBottom.length);
				
						for (j = 0; j < XBottom.length; j++) { // Crop if bottom boundaries exist
							
							selectWindow(window_title);
							rect_length = XBottom[j]-XTop[j];
							//(XTop[j]);
							//print(rect_length);
							makeRectangle(0, XTop[j], width, rect_length);
							roiManager("Add");
							run("Duplicate...", "duplicate");
							saveAs("Tiff", folderSave+ File.separator +title+"_Series_"+series+"_ROI_"+j);
							close();
						}
						
						// Save ROI manager
						selectWindow(window_title);
						roiManager("Save", folderSave+ File.separator +title+"_Series_"+series+"_ROI.zip");
						XTop = newArray();
						XBottom =  newArray();
						BrightArea = 0;
						roiManager("reset");
						close();
						
						// Save MIP if ticked
						if (save_max) {
							selectWindow("MAX_"+window_title);
							run("Rotate 90 Degrees Right");
							saveAs("Tiff", folderSave+ File.separator +title+"_Series_"+series+"_MIP");
							close();
						}
						else {
							selectWindow("MAX_"+window_title);
							close();
						}
				
					}
				}
				run("Close All");
				IJ.freeMemory();
				run("Collect Garbage");
			}
		}
}