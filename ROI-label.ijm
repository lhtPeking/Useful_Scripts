inputFolder = "/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/LLPS-Property/6m/6m-17/Counter3D/";
outputFolder = inputFolder + "ROIlabeled/";
File.makeDirectory(outputFolder);

list = getFileList(inputFolder);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif")) { // 仅处理TIF文件
        open(inputFolder + list[i]); // 打开图像
        setBatchMode(true); // 开启批处理模式

        stackSize = nSlices();
        for (j = 1; j <= stackSize; j++) {
            setSlice(j); // 遍历每个切片
            run("Label Map to ROIs", "connectivity=C8 vertex_location=Corners");
        }

        setBatchMode(false);
        saveAs("Tiff", outputFolder + list[i]); // 保存处理后的图像
        // close();
    }
}