inputFolder = "/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/LLPS-Property/FL/FL-15/original/"; // 选择文件夹
outputFolder = inputFolder + "Filtered/"; // 输出到“Filtered”文件夹
File.makeDirectory(outputFolder);

list = getFileList(inputFolder);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif")) { // 仅处理TIF文件
        open(inputFolder + list[i]); // 打开图像
        setBatchMode(true); // 开启批处理模式

        stackSize = nSlices();
        for (j = 1; j <= stackSize; j++) {
            setSlice(j); // 遍历每个切片
            run("Bandpass Filter...", "filter_large=30 filter_small=2 suppress=None tolerance=5");
        }

        setBatchMode(false);
        saveAs("Tiff", outputFolder + list[i]); // 保存处理后的图像
        close(); // 关闭当前图像
    }
}