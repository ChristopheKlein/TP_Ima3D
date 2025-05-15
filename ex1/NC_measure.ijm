macro "NC_measure4"{

//BBBC 014


d=10; //NUCL_DIAM
watershed=true;
iter=1;
segmentation_noise=0;
min_cell_surface=7;
max_cell_surface=1000;

//Image path
getDimensions(width, height, channels, slices, frames);
getPixelSize(unit, pix_size, pix_size);
unit="microns";
run("Properties...", "channels="+channels+" slices="+slices+" frames="+frames+" unit="+unit+" pixel_width="+pix_size+" pixel_height="+pix_size+" voxel_depth=1.0000000");
dir=getInfo("image.directory");
file=getInfo("image.filename");
name=getTitle();
original=getImageID();
run("Select None");
//run("Size...", "width=512 height=512 depth=4 constrain average interpolation=Bilinear");

setSlice(1);
run("Duplicate...", "title=DAPI");

//Nucl_Mask
selectImage("DAPI");
run("Duplicate...", "title=Mask_Nucl");
run("Gaussian Blur...", "sigma=2");
//setAutoThreshold("Mean dark");
setAutoThreshold("Otsu dark");
run("Convert to Mask");

//Spot enhancing on nuclei channel by Difference of Gaussian (scaled)
selectImage("DAPI");
run("Duplicate...", "title=sig1");
run("Duplicate...", "title=sig2");
sigma1=0.5*d/sqrt(2);
sigma2=sqrt(2)*d*0.5;
selectImage("sig1");
run("Gaussian Blur...", "sigma="+sigma1+" scaled");
selectImage("sig2");
run("Gaussian Blur...", "sigma="+sigma2+" scaled");
imageCalculator("Substract create 32-bit", "sig1","sig2");
run("Grays");
rename("DoG");
DoG=getImageID();
selectWindow("sig1");
close();
selectWindow("sig2");
close();

//Nuclei
selectImage(DoG);
run("Find Maxima...", "noise="+segmentation_noise+" output=[Segmented Particles]");
rename("Particules");
imageCalculator("AND", "Particules","Mask_Nucl");
selectImage("Particules");
run("Options...", "iterations="+iter+" count=3 black pad do=Open");
if(watershed)
	run("Watershed");

roiManager("Reset");
//run("Analyze Particles...", "size="+min_cell_surface+"-"+max_cell_surface+" show=Masks exclude in_situ");
run("Analyze Particles...", "size="+min_cell_surface+"-"+max_cell_surface+" show=Masks exclude add in_situ");
run("Options...", "iterations="+iter+" count=3 black pad do=Open");
rename("nuclei");

//mask SKIZ
selectWindow("nuclei");
run("Duplicate...", "title=SKIZ");
run("Voronoi");
getMinAndMax(min, max);
setThreshold(1, 255);
run("Make Binary", "thresholded remaining black");

//mask cells
selectImage(original);
setSlice(2);
run("Duplicate...", "title=cells ");
run("Gaussian Blur...", "sigma=1");
//setThreshold(5, 255);
setAutoThreshold("Huang dark");
run("Convert to Mask");
run("Options...", "iterations="+iter+" count=3 black pad do=Close");

//mask noyau erode 1
selectWindow("nuclei");
run("Duplicate...", "title=eroded_nuclei");
run("Options...", "iterations=2 count=1 black pad do=Erode");
run("8-bit");

//mask noyau dilate 1
selectWindow("nuclei");
run("Duplicate...", "title=dilated_nuclei2");
run("Options...", "iterations=1 count=1 black do=Dilate");
imageCalculator("AND", "dilated_nuclei2","SKIZ");
imageCalculator("AND", "dilated_nuclei2","cells");
//run("BinaryGeodesicDilateNoMerge8 ", "mask=cells seed=dilated_nuclei2 iterations=1");
//run("8-bit");

//mask cytoplasm
selectWindow("cells");
run("Duplicate...", "title=cytoplasm ");
selectWindow("dilated_nuclei2");
run("Invert");
imageCalculator("AND", "cytoplasm","dilated_nuclei2");
selectWindow("dilated_nuclei2");
run("Invert");

//Nuclei dilated 4 == ROI
selectWindow("dilated_nuclei2");
run("Duplicate...", "title=dilated_nuclei4");
run("Options...", "iterations=4 count=1 black do=Dilate");
imageCalculator("AND", "dilated_nuclei4","SKIZ");
imageCalculator("AND", "dilated_nuclei4","cells");
//run("BinaryGeodesicDilateNoMerge8 ", "mask=cells seed=dilated_nuclei4 iterations=4");
//run("8-bit");
roiManager("reset");
run("Analyze Particles...", "  show=Masks exclude add in_situ");

//greylevel images
selectImage(original);
setSlice(2);
run("Duplicate...", "title=NFKB_nucl_grey");
imageCalculator("AND", "NFKB_nucl_grey","eroded_nuclei");

selectImage(original);
setSlice(1);
run("Duplicate...", "title=DAPI_nucl_grey");
imageCalculator("AND", "DAPI_nucl_grey","eroded_nuclei");

selectWindow("dilated_nuclei2");
run("Invert");
selectImage(original);
setSlice(2);
run("Duplicate...", "title=NFKB_cyto_grey");
imageCalculator("AND", "NFKB_cyto_grey","dilated_nuclei2");


//renumber ROIs
n=roiManager("count");
	for (i=0;i<n;i++){
	roiManager("select",i);
	roiManager("Rename", i+1);
	}
run("Select None");

//measure	
run("Set Measurements...", "area mean standard modal min centroid center bounding integrated median skewness kurtosis limit display redirect=None decimal=1");
run("Images to Stack", "name="+name+" title=grey use");
run("Select None");
setThreshold(1, 255);
roiManager("Deselect");
setSlice(1);
roiManager("Measure");
setSlice(2);
roiManager("Measure");
setSlice(3);
roiManager("Measure");


//Create a result table if none
if(!isOpen("NC_results")){
	run("New... ", "name=NC_results type=Table"); 	
	print("[NC_results]","\\Headings:cell_id\tLabel\tMean_Nuc\tMean_cyto\tNC_ratio"); 
	}
	
//Get results in the result table and report in the new result table with one row for each cell
N=nResults/3;
label=newArray(N);
meanN=newArray(N);
meanC=newArray(N);
for(i=0;i<N;i++){
	label[i]=substring(getResultLabel(i), 0, indexOf(getResultLabel(i), "_"));
	meanN[i]=getResult("Mean",i);
	meanC[i]=getResult("Mean",i+2*N);
}

for(i=0;i<N;i++){
	print("[NC_results]",(i+1)+"\t"+label[i]+"\t"+meanN[i]+"\t"+meanC[i]+"\t"+meanN[i]/meanC[i]); 
}


roiManager("Show All");
resetThreshold();
run("Grays");

//SaveROI
roiManager("Deselect");
path=dir+File.separator+file+"_ROI.zip";
roiManager("Save", path);
roiManager("Reset");

//Save results
path=dir+File.separator+file+"_Result_table.xls";
saveAs("results", path);

//Save NC ratio
selectWindow("NC_results"); 
path=dir+File.separator+file+"_NC_ratio.xls";
saveAs("results", path);

/*
//close all
run("Close All");

selectWindow("NC_results"); 
run("Close");

selectWindow("Results"); 
run("Close");
*/
}



