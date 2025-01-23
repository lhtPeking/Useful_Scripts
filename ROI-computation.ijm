input = "/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/LLPS-Property/FL/FL-14/"; 
//roiFolder = getDirectory("/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/quantification_1118/Watered/ROIlabeled/Set/"); // 小ROI文件夹
//bigRoiFolder = getDirectory("/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/quantification_1118/Watered/ROIlabeled/Whole/"); // 大ROI文件夹
input_sROI = input + "Counter3D/ROIlabeled/RoiSet.zip";
input_lROI = input + "original/RoiSet.zip";
inputFolder_figure = input + "original/";
outputFolder = input + "ROI-Processed/"; // 输出文件夹
File.makeDirectory(outputFolder);

list = getFileList(inputFolder_figure); // 获取图像文件列表
outputFile = outputFolder + "Results.csv"; // 保存结果的CSV文件

// 写入CSV文件头
File.saveString("File Name,Slice,Small ROI Weighted Mean,Big ROI Minus Small ROI Mean\n", outputFile);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif")) { // 仅处理TIF文件
        open(inputFolder_figure + list[i]); // 打开图像
        setBatchMode(true); // 开启批处理模式

        stackSize = nSlices(); // 获取z-stack的切片数

        // 加载小ROI文件
        // roiFile = "/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/quantification_1118/Watered/ROIlabeled/Set/RoiSet.zip"; // 小ROI文件
        if (File.exists(input_sROI)) {
            roiManager("Reset"); // 清空ROI管理器
            roiManager("Open", input_sROI); // 加载小ROI
            print("Loaded Small ROI file: " + input_sROI);
        } else {
            print("Small ROI file not found: " + input_sROI);
            continue; // 如果没有对应的ROI文件，则跳过该图像
        }

        roiCount = roiManager("Count"); // 获取小ROI数量

        // 加载大ROI文件
        // bigRoiFile = "/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/quantification_1118/Watered/ROIlabeled/Whole/RoiWhole.zip"; // 大ROI文件
        if (File.exists(input_lROI)) {
            roiManager("Open", input_lROI); // 加载大ROI
            print("Loaded Big ROI file: " + input_lROI);
        } else {
            print("Big ROI file not found: " + input_lROI);
            continue; // 如果没有对应的大ROI文件，则跳过该图像
        }

        // 遍历每个切片
        for (j = 1; j <= stackSize; j++) { // 遍历每个切片
            setSlice(j); // 切换到当前切片

            // 初始化变量
            totalWeightedIntensity = 0;
            totalSmallArea = 0;
            totalSmallIntensity = 0;
            bigArea = 0;
            bigMean = 0;
            totalBigArea = 0;
            bigTotalIntensity = 0;

            // 遍历小ROI，计算小ROI的面积加权平均亮度
            for (k = 0; k < roiCount; k++) {
                roiManager("Select", k); // 选择小ROI
                // roiNames = split(roiManager("List"), "\n"); // 获取ROI名称列表
                // roiName = roiNames[0]; // 获取当前小ROI名称
                run("Measure");
                area = getResult("Area", nResults() - 1);
                mean = getResult("Mean", nResults() - 1);
                totalWeightedIntensity += area * mean;
                totalSmallArea += area;
                totalSmallIntensity += area * mean;
            }

            // 计算小ROI的面积加权平均亮度
            if (totalSmallArea > 0) {
                smallROIWeightedMean = totalWeightedIntensity / totalSmallArea;
            } else {
                smallROIWeightedMean = NaN; // 如果没有小ROI
            }

            // 查找大ROI
            for (k = roiCount; k < roiManager("Count"); k++) { // 大ROI在小ROI之后
                roiManager("Select", k); // 选择大ROI
                run("Measure");
                bigArea = getResult("Area", nResults() - 1);
                bigMean = getResult("Mean", nResults() - 1);
                totalBigArea += bigArea;
                bigTotalIntensity += bigArea * bigMean;
            }

            // 计算大ROI扣除小ROI的平均亮度
            bigMinusSmallArea = totalBigArea - totalSmallArea;
            bigMinusSmallIntensity = bigTotalIntensity - totalSmallIntensity;
            if (bigMinusSmallArea > 0) {
                bigMinusSmallMean = bigMinusSmallIntensity / bigMinusSmallArea;
            } else {
                bigMinusSmallMean = NaN; // 如果扣除后没有剩余区域
            }

            // 保存结果到CSV文件
            File.append(list[i] + "," + j + "," + smallROIWeightedMean + "," + bigMinusSmallMean + "\n", outputFile);
        }

        setBatchMode(false); // 关闭批处理模式
        close(); // 关闭当前图像
    }
}

// 提示完成
print("Processing complete. Results saved to: " + outputFile);