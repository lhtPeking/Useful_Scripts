input = "/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/LLPS-Property/FL/FL-14/";
inputFolder = input + "original/Filtered/";
outputFolder = input + "Counter3D/";
roiFile = "/Users/haotianli/Library/CloudStorage/OneDrive-Personal/MouseData/condensateID/LLPS-Property/FL/FL-14/original/RoiSet.zip"; // 指定 ROI 文件

File.makeDirectory(outputFolder); // 创建输出目录

list = getFileList(inputFolder);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif")) { // 仅处理 TIF 文件
        open(inputFolder + list[i]); // 打开图像

        // 检查并加载 ROI 文件
        if (File.exists(roiFile)) {
            roiManager("Reset"); // 清空 ROI 管理器
            roiManager("Open", roiFile); // 加载 ROI
            print("Loaded ROI file: " + roiFile);
        } else {
            print("ROI file not found: " + roiFile);
            continue; // 如果没有对应的 ROI 文件，则跳过该图像
        }

        // 获取切片数和 ROI 数量
        slideCount = nSlices(); // 当前图像的切片数
        roiCount = roiManager("Count"); // ROI 总数
        print(slideCount + roiCount);

        // 确保 ROI 数量与切片数一致
        if (roiCount != slideCount) {
            print("Error: Number of ROIs (" + roiCount + ") does not match the number of slides (" + slideCount + ").");
            continue;
        }

        // 遍历每张切片，逐张应用对应的 ROI
        for (j = 1; j <= slideCount; j++) {
            setSlice(j); // 切换到第 j 张切片
            roiManager("Select", j - 1); // 选择对应的第 j 个 ROI

            // 设置 ROI 外区域为 0（保留 ROI 内部亮度）
            run("Create Mask");
            run("Restore Selection"); // 恢复选区
            run("Clear Outside"); // 清除 ROI 外部区域，将亮度设置为 0

            // 阈值化并转换为二值图像
            setAutoThreshold("Default dark no-reset");
            setThreshold(50, 255); // 设置阈值范围
            setOption("BlackBackground", true);
            run("Convert to Mask", "background=Dark black"); // 转换为二值图像
        }

        // 对当前图像运行 MorphoLibJ 的 3D 分析
        run("Distance Transform Watershed 3D", "distances=[Borgefors (3,4,5)] output=[16 bits] normalize dynamic=0.50 connectivity=26");
        saveAs("Tiff", outputFolder + list[i] + "_3D_segmented.tif"); // 保存分割结果

        // 运行 3D 区域分析
        run("Analyze Regions 3D", "voxel_count volume surface_area mean_breadth sphericity euler_number bounding_box centroid equivalent_ellipsoid ellipsoid_elongations max._inscribed surface_area_method=[Crofton (13 dirs.)] euler_connectivity=26 show_rois export_rois");
        saveAs("Results", outputFolder + list[i] + "_3D_analysis.csv"); // 保存分析结果

        close(); // 关闭当前图像
    }
}