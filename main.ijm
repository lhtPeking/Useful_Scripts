function calculateIntensityThreshold_K_Percent(imagePath, ROIPath, K){
    open(imagePath);
    // 检查并加载 ROI 文件
    if (File.exists(ROIPath)) {
        roiManager("Reset"); // 清空 ROI 管理器
        roiManager("Open", ROIPath); // 加载 ROI
        print("Loaded ROI file: " + ROIPath);
    } else {
        print("ROI file not found: " + ROIPath);
    }
    slideCount = nSlices;
    roiCount = roiManager("count");
    if (slideCount != roiCount) {
        print("Error: Slide count (" + slideCount + ") does not match ROI count (" + roiCount + ")");
        return;
    }

    lowerBoundaries = newArray(slideCount);
    // 遍历每张切片，逐张应用对应的 ROI
    for (j = 1; j <= slideCount; j++) {
        setSlice(j); // 切换到第 j 张切片
        roiManager("Select", j - 1); // 选择对应的第 j 个 ROI

        // 设置 ROI 外区域为 0（保留 ROI 内部亮度）
        run("Clear Outside"); // 清除 ROI 外部区域，将亮度设置为 0
        
        // 计算 ROI 内部像素值的 K% 分位数
        run("Histogram");
        Table.showHistogramTable;
        Counts = Table.getColumn("count");
        run("Close");
        close();
        
        totalPixels = 0;

        for (i = 0; i <= 255; i++){
        	totalPixels += Counts[i];
        }
        
        print("totalPixels for slice " + (j) + " in image " + File.getName(imagePath) + ": " + totalPixels);
        
        KthPercentile = totalPixels * K / 100;
        print("KthPercentile: " + KthPercentile);

        for (i = 255; i >= 0; i--){
        	KthPercentile -= Counts[i];
        	if (KthPercentile <= 0){
        		lowerBoundaries[j-1] = i;
        		break;
        	}
        }
        selectImage(File.getName(imagePath));
    }

    for (i = 0; i < lowerBoundaries.length; i++){
    	print("Lower boundary for slice " + (i+1) + " in image " + File.getName(imagePath) + ": " + lowerBoundaries[i]);
    }

    close();

    return lowerBoundaries;
}

K = 1;


// 加载单个文件夹中的信息:重构后的图片.tif、细胞核ROI.zip
inputFolder = "/Users/haotianli/Downloads/LLPS-quantification-series-1212/LLPS-Property-current/GFP-Prox1.FL/FFT_checked/Croped/ExpressionLevelControlled/GFP_FL_05[4162]/"

list = getFileList(inputFolder);
// 分别获得图片和ROI的路径
for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif")) {
        imagePath = inputFolder + list[i];
    }
    if (endsWith(list[i], ".zip")) {
        ROIPath = inputFolder + list[i];
    }
}

lowerBoundary = calculateIntensityThreshold_K_Percent(imagePath, ROIPath, K);
// lowerBoundary的计算是用ROI蒙版之后的，细胞核内的像素值的K%分位数作为阈值

open(imagePath);
if (File.exists(ROIPath)) {
    roiManager("Reset"); // 清空 ROI 管理器
    roiManager("Open", ROIPath); // 加载 ROI
    print("Loaded ROI file: " + ROIPath);
} else {
    print("ROI file not found: " + ROIPath);
}

for (j = 1; j <= nSlices; j++) {
    setSlice(j);  // 切换到第 j 张切片
    roiManager("Select", j - 1); // 选择对应的第 j 个 ROI

    run("Clear Outside"); // 清除 ROI 外部区域，将亮度设置为 0

    run("Threshold...");
    setAutoThreshold("Default dark no-reset");
    setThreshold(lowerBoundary[j-1], 255); // 使用每个切片的阈值
    setOption("BlackBackground", true);
    run("Convert to Mask", "background=Dark black"); // 转换为二值图像

    selectImage(File.getName(imagePath));
}

saveAs("Tiff", imagePath + "_binary.tif");

// 用3D objects counter计算condensate property(这一步涉及到用control组对condensate的体积下限的划定):
run("3D Objects Counter", "threshold=128 slice=4 min.=15 max.=562500 exclude_objects_on_edges objects surfaces statistics summary");
saveAs("Results", inputFolder + "condensate_property.csv");


// 用3D objects counter计算ROI总体积:


// close();