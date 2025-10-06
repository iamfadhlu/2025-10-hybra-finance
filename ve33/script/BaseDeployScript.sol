// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";

abstract contract BaseDeployScript is Script {

    string public outputFilename = vm.envString("OUTPUT_FILENAME");

    // 简单的字符串连接函数
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    // 获取输出文件的完整路径
    function getOutputPath(string memory filename) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory path = concat(root, "/script/constants/output/");
        path = concat(path, filename);
        path = concat(path, "-");
        path = concat(path, outputFilename);
        path = concat(path, ".json");
        return path;
    }

    // 获取输入文件的完整路径（用于读取之前步骤的输出）
    function getInputPath(string memory filename) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory path = concat(root, "/script/constants/output/");
        path = concat(path, filename);
        path = concat(path, "-");
        path = concat(path, outputFilename);
        path = concat(path, ".json");
        return path;
    }

    // 获取配置文件路径（从 CONSTANTS_FILENAME 环境变量读取）
    function getConfigPath() internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory constantsFilename = vm.envString("CONSTANTS_FILENAME");
        string memory path = concat(root, "/script/constants/");
        path = concat(path, constantsFilename);
        path = concat(path, ".json");
        return path;
    }
}