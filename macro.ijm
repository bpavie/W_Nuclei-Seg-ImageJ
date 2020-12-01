//Macro requirement:
//FeatureJ so the ImageScience plugin : https://imagej.net/ImageScience
//MorpholibJ : https://imagej.net/MorphoLibJ

//Test the macro:
/*
java -Xmx1000m -cp .\jars\ij-1.53c.jar ij.ImageJ --headless --console -macro  "G:\macro.ijm" "input=G:\in, output=G:\out, radius=5, proeminence=0.45"

//Don't forget to modify the :
- path to your Fiji installation,
- imageJ version
- input folder path (and make sure the folder exist and the images are inside the folder)
- out folder path (and make sure the folder exist)
*/
setBatchMode(true);


// Path to input image and output image (label mask)
inputDir = "/dockershare/666/in/";
outputDir = "/dockershare/666/out/";

// Functional parameters
LAP_RAD = 5;
PROEMINENCE = 0.45;

arg = getArgument();
//print("arg:"+arg);
parts = split(arg, ",");

for(i=0; i<parts.length; i++) {
	nameAndValue = split(parts[i], "=");
	//print("nameAndValue[0]:"+nameAndValue[0]);
	//print("nameAndValue[0]:"+nameAndValue[1]);
	if (indexOf(nameAndValue[0], "input")>-1) inputDir=nameAndValue[1];
	if (indexOf(nameAndValue[0], "output")>-1) outputDir=nameAndValue[1];
	if (indexOf(nameAndValue[0], "radius")>-1) LAP_RAD=nameAndValue[1];
	if (indexOf(nameAndValue[0], "proeminence")>-1) PROEMINENCE=nameAndValue[1];
}

images = getFileList(inputDir);

for(i=0; i<images.length; i++) {
	image = images[i];
	if (endsWith(image, ".tif")) {
		// Open image
		open(inputDir + "/" + image);
		wait(100);
		// Processing
		segmentNuclei(LAP_RAD, PROEMINENCE);
		// Export results
		save(outputDir + "/" + image);
		// Cleanup
		run("Close All");
	}
}
run("Quit");
		
function segmentNuclei(lapRad, proeminence) {	
	inputID = getImageID();
    rename("original");
	inputTitle = getTitle();
	run("Subtract Background...", "rolling=50");
	run("FeatureJ Laplacian", "compute smoothing="+lapRad);
	//run("Morphological Filters", "operation=Laplacian element=Disk radius="+lapRad);
	laplacianID = getImageID();
	run("Find Maxima...", "prominence="+proeminence+" light output=[Single Points]");
	maximaID = getImageID();
	rename("maxima-result");
	maximaTitle = getTitle();
	selectImage(inputID);
	setAutoThreshold("Default dark");
	run("Convert to Mask");
	options="input="+inputTitle+" marker=["+maximaTitle+"] mask="+inputTitle+" binary calculate use";
	//Run marker controlled watershed
	run("Marker-controlled Watershed", options);
	//Convert the 32 bit float label mask to 16 bits
	run("16-bit", "" );
	//Remap labels so they are continues
	run("Remap Labels");
	//run("glasbey on dark");
	//setThreshold(1.0000, 1000000000000000000000000000000.0000);
	//run("Convert to Mask");
	close("\\Others");
}