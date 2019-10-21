//
//  NumberRecognizer.swift
//
//  Created by PVDPLUS on 2017/4/18.
//  Copyright © 2017年 PVDPLUS. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ImageIO

class NumberRecognizer{
    //取初始畫面相關全域變數
    var setTempBasicFrame:Bool
    var tempBasicFrame:[Int]
    var setBasicFrame:Bool
    var basicFrame:[Int]
    let passFrameMin:Int
    var passFrameCounter:Int
    init(initSetTempBasicFrame:Bool, initTempBasicFrame:[Int], initSetBasicFrame:Bool, initBasicFrame:[Int], initPassFrameMin:Int, initPassFrameCounter:Int){
        setTempBasicFrame = initSetTempBasicFrame
        tempBasicFrame = initTempBasicFrame
        setBasicFrame = initSetBasicFrame
        basicFrame = initBasicFrame
        passFrameMin = initPassFrameMin
        passFrameCounter = initPassFrameCounter
    }
    
    //主函式 (回傳運算後輸出值)
    func recognizer(image: UIImage) -> (nowMode:String, cardColor:String, coordsOfCenter:String, totalCards:Int, cardNumber:String,setTempBasicFrame:Bool, tempBasicFrame:[Int], setBasicFrame:Bool, basicFrame:[Int], passFrameMin:Int, passFrameCounter:Int) {
        // get information about image
        let imageref = image.cgImage!
        let width = imageref.width
        let height = imageref.height
        let imageLength = width * height
        
        // initialize return parameters
        var nowMode = "Initializing";
        var cardColor = "None";
        var coordsOfCenter = "Not Exist";
        var totalCards = 0;
        var cardNumber = "None";
        
        // create new bitmap context
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = Pixel.bitmapInfo
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)!
        
        // draw image to context
        
        let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        context.draw(imageref, in: rect)
        
        // manipulate binary data
        
        guard let buffer = context.data else {
            print("unable to get context data")
            return (nowMode, cardColor, coordsOfCenter, totalCards, cardNumber,setTempBasicFrame, tempBasicFrame, setBasicFrame, basicFrame, passFrameMin, passFrameCounter)
        }
        
        let pixels = buffer.bindMemory(to: Pixel.self, capacity: width * height)
        var numberColor = Array<Int>()
        
        //取得RGBA, 轉灰階值
        if(setBasicFrame == false){
            for offset in 0 ..< imageLength {
                let green = Float(pixels[offset].green)
                let alpha = pixels[offset].alpha
                //只使用綠色波段
                let greyScale = UInt8(green)
                pixels[offset] = Pixel(red: greyScale, green: greyScale, blue: greyScale, alpha: alpha)
                numberColor.append(Int(greyScale))
                
            }
            //呼叫運算初始畫面函式
            processInitView(myColor: numberColor, width: width, height: height)
        }
        else
        {
            nowMode = "Detecting"
            let threshold = 30
            var blueCount = 0
            var purpleCount = 0
            for offset in 0 ..< imageLength {
                let red = Float(pixels[offset].red)
                let green = Float(pixels[offset].green)
                let blue = Float(pixels[offset].blue)
                let alpha = pixels[offset].alpha
                //只使用綠色波段
                let greyScale = UInt8(green)
                let difference = Swift.abs(tempBasicFrame[offset] - Int(greyScale))
                //變動區塊轉為黑色
                let diffPixelGrayScale = UInt8(0)
                if(difference >= threshold){
                    if(red - green >= 20 && blue - green >= 20){
                        pixels[offset] = Pixel(red: diffPixelGrayScale, green: diffPixelGrayScale, blue: diffPixelGrayScale, alpha: alpha)
                        purpleCount += 1
                    }
                    else if(blue - red >= 30 && blue - green >= 30){
                        pixels[offset] = Pixel(red: diffPixelGrayScale, green: diffPixelGrayScale, blue: diffPixelGrayScale, alpha: alpha)
                        blueCount += 1
                    }
                    else{
                        let greyScale = UInt8(255)
                        pixels[offset] = Pixel(red: greyScale, green: greyScale, blue: greyScale, alpha: alpha)
                    }
                }
                    //未變動區塊轉為白色
                else{
                    let greyScale = UInt8(255)
                    pixels[offset] = Pixel(red: greyScale, green: greyScale, blue: greyScale, alpha: alpha)
                }
            }
            //邊緣萃取, 將物件內部標為白色, 邊緣保留為黑色
            
            var horizontalArr = [Int](repeating:0, count:height)
            var verticalArr = [Int](repeating:0, count:width)
            var minX = 0
            var maxX = 0
            var minY = 0
            var maxY = 0
            
            
            for row in 1 ..< height - 1 {
                for col in 1 ..< width - 1 {
                    let offset = Int(row * width + col)
                    if(Int(pixels[offset].red) == 0){
                        let n1 = Int(pixels[((row-1) * width + (col-1))].red)
                        let n2 = Int(pixels[((row-1) * width + col)].red)
                        let n3 = Int(pixels[((row-1) * width + (col+1))].red)
                        let n4 = Int(pixels[(row * width + (col-1))].red)
                        let n5 = Int(pixels[(row * width + (col+1))].red)
                        let n6 = Int(pixels[((row+1) * width + (col-1))].red)
                        let n7 = Int(pixels[((row+1) * width + col)].red)
                        let n8 = Int(pixels[((row+1) * width + (col+1))].red)
                        if (n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 != 0){
                            horizontalArr[height-1-row] += 1
                            verticalArr[col] += 1
                        }
                    }
                }
            }
            
            for row in 0 ..< horizontalArr.count {
                if(horizontalArr[row] != 0){
                    if(minY == 0){
                        minY = row
                    }
                    maxY = row
                }
            }
            
            for col in 0 ..< verticalArr.count {
                if(verticalArr[col] != 0){
                    if(minX == 0){
                        minX = col
                    }
                    maxX = col
                }
            }
            
            if(minX != 0 && maxX != 0 && minY != 0 && maxY != 0){
                //確認minX, minY坐標
                var minXCoord = [Int]()
                var minYCoord = [Int]()
                
                for row in 0 ..< height {
                    let offset = Int((height - row - 1) * width + minX)
                    if(Int(pixels[offset].red) == 0){
                        minXCoord.append(minX)
                        minXCoord.append(row)
                        break
                    }
                }
                
                for col in 0 ..< width {
                    let offset = Int((height - minY - 1) * width + col)
                    if(Int(pixels[offset].red) == 0){
                        minYCoord.append(col)
                        minYCoord.append(minY)
                        break
                    }
                }
                //旋轉校正角
                var translateAngle = 0
                //圖標區域中心點
                var centerX = (minX + maxX)/2
                var centerY = (minY + maxY)/2
                //minX, minY縱向橫向連線距離皆小於40pixel時, 不調整旋轉校正
                if(Swift.abs(minXCoord[0] - minYCoord[0]) >= 40 || Swift.abs(minXCoord[1] - minYCoord[1]) >= 40){
                    //逆時針旋轉校正
                    if(Swift.abs(minXCoord[0] - minYCoord[0]) > Swift.abs(minXCoord[1] - minYCoord[1])){
                        translateAngle = Int(atan(Swift.abs(Double(minXCoord[1]) - Double(minYCoord[1])) / Swift.abs(Double(minXCoord[0]) - Double(minYCoord[0]))) * 180 / M_PI)
                    }
                        //順時針旋轉校正
                    else if(Swift.abs(minXCoord[0] - minYCoord[0]) < Swift.abs(minXCoord[1] - minYCoord[1])){
                        translateAngle = Int(atan(Swift.abs(Double(minXCoord[0]) - Double(minYCoord[0])) / Swift.abs(Double(minXCoord[1]) - Double(minYCoord[1]))) * 180 / M_PI)
                    }
                    else{
                        minXCoord[0] += 1
                        translateAngle = Int(atan(Swift.abs(Double(minXCoord[1]) - Double(minYCoord[1])) / Swift.abs(Double(minXCoord[0]) - Double(minYCoord[0]))) * 180 / M_PI)
                    }
                    
                    let halfImgWidth = centerX - minX
                    let halfImgHeight = centerY - minY
                    
                    var newImgArray = [Int](repeating:0,count:height*width)
                    //計算中心點旋轉後的平移量
                    let (xDiff,yDiff) = centerMove(centerX:centerX, centerY:centerY, halfImgWidth:halfImgWidth, halfImgHeight:halfImgHeight, translateAngle:translateAngle, minXCoord: minXCoord, minYCoord: minYCoord, width:width, height:height)!
                    //旋轉轉換+平移校正
                    for row in minY ..< maxY+1 {
                        for col in minX ..< maxX+1 {
                            let offset = Int((height - row - 1) * width + col)
                            if(Int(pixels[offset].red) == 0){
                                let xCosTheta = Double(col - halfImgWidth) * cos(Double(translateAngle) * M_PI / 180)
                                let ySinTheta = Double(row - halfImgHeight) * sin(Double(translateAngle) * M_PI / 180)
                                let xSinTheta = Double(col - halfImgWidth) * sin(Double(translateAngle) * M_PI / 180)
                                let yCosTheta = Double(row - halfImgHeight) * cos(Double(translateAngle) * M_PI / 180)
                                
                                var newCol = 0
                                var newRow = 0
                                if(Swift.abs(minXCoord[0] - minYCoord[0]) > Swift.abs(minXCoord[1] - minYCoord[1])){
                                    newCol = Int(xCosTheta - ySinTheta)
                                    newRow = Int(xSinTheta + yCosTheta)
                                }
                                else if(Swift.abs(minXCoord[0] - minYCoord[0]) < Swift.abs(minXCoord[1] - minYCoord[1])){
                                    newCol = Int(xCosTheta + ySinTheta)
                                    newRow = Int(0 - xSinTheta + yCosTheta)
                                }
                                
                                let newOffset = Int((height - newRow - 1 - halfImgHeight + yDiff) * width + newCol + halfImgWidth - xDiff)
                                
                                if(newOffset >= height * width || newOffset < 0){
                                    continue
                                }
                                newImgArray[newOffset] = 1
                            }
                        }
                    }
                    //更新圖片
                    for offset in 0 ..< newImgArray.count {
                        if(newImgArray[offset] == 1){
                            let greyScale = UInt8(0)
                            pixels[offset] = Pixel(red: greyScale, green: greyScale, blue: greyScale, alpha: UInt8(255))
                        }
                            //未變動區塊轉為白色
                        else{
                            let greyScale = UInt8(255)
                            pixels[offset] = Pixel(red: greyScale, green: greyScale, blue: greyScale, alpha: UInt8(255))
                        }
                    }
                    
                    horizontalArr = [Int](repeating:0, count:height)
                    verticalArr = [Int](repeating:0, count:width)
                    
                    for row in 1 ..< height - 1 {
                        for col in 1 ..< width - 1 {
                            let offset = Int(row * width + col)
                            if(Int(pixels[offset].red) == 0){
                                let n1 = Int(pixels[((row-1) * width + (col-1))].red)
                                let n2 = Int(pixels[((row-1) * width + col)].red)
                                let n3 = Int(pixels[((row-1) * width + (col+1))].red)
                                let n4 = Int(pixels[(row * width + (col-1))].red)
                                let n5 = Int(pixels[(row * width + (col+1))].red)
                                let n6 = Int(pixels[((row+1) * width + (col-1))].red)
                                let n7 = Int(pixels[((row+1) * width + col)].red)
                                let n8 = Int(pixels[((row+1) * width + (col+1))].red)
                                
                                if (n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 != 0){
                                    horizontalArr[height-1-row] += 1
                                    verticalArr[col] += 1
                                }
                            }
                        }
                    }
                    minX = 0
                    minY = 0
                    for row in 0 ..< horizontalArr.count {
                        if(horizontalArr[row] != 0){
                            if(minY == 0){
                                minY = row
                            }
                            maxY = row
                        }
                    }
                    for col in 0 ..< verticalArr.count {
                        if(verticalArr[col] != 0){
                            if(minX == 0){
                                minX = col
                            }
                            maxX = col
                        }
                    }
                }
                for row in minY ..< maxY + 1 {
                    //由左右移除邊緣區塊
                    if(row <= minY + 20 || row >= maxY - 20){
                        for col in minX ..< maxX {
                            let offset = Int((height - row - 1) * width + col)
                            pixels[offset] = Pixel(red: UInt8(255), green: UInt8(255), blue: UInt8(255), alpha: UInt8(255))
                        }
                    }
                    //由上向下移除邊緣區塊
                    for col in minX ..< minX + 15 {
                        let offset = Int((height - row - 1) * width + col)
                        if(Int(pixels[offset].red) == 0){
                            if(Int(pixels[offset + 1].red) == 0){
                                pixels[offset] = Pixel(red: UInt8(255), green: UInt8(255), blue: UInt8(255), alpha: UInt8(255))
                            }
                            if(Int(pixels[offset + 1].red) == 255){
                                pixels[offset] = Pixel(red: UInt8(255), green: UInt8(255), blue: UInt8(255), alpha: UInt8(255))
                                if(Int(pixels[offset + 2].red) == 255 && Int(pixels[offset + 3].red) == 255){
                                    break
                                }
                            }
                        }
                    }
                    //由下向上移除邊緣區塊
                    for col in stride(from:maxX, to: maxX - 15, by: -1) {
                        let offset = Int((height - row - 1) * width + col)
                        if(Int(pixels[offset].red) == 0){
                            if(Int(pixels[offset - 1].red) == 0){
                                pixels[offset] = Pixel(red: UInt8(255), green: UInt8(255), blue: UInt8(255), alpha: UInt8(255))
                            }
                            if(Int(pixels[offset - 1].red) == 255){
                                pixels[offset] = Pixel(red: UInt8(255), green: UInt8(255), blue: UInt8(255), alpha: UInt8(255))
                                if(Int(pixels[offset - 2].red) == 255 && Int(pixels[offset - 3].red) == 255){
                                    break
                                }
                            }
                        }
                    }
                }
                //圖標數量, 顏色確認
                //以顏色判斷是否有不同色兩張
                
                if(blueCount >= 1000 && purpleCount >= 1000){
                    cardColor = "Blue, Purple"
                    totalCards = 2
                }
                    //以座標判斷是否有兩張
                else{
                    //兩張卡片為縱列或橫列的狀況
                    if(Int(Swift.abs((maxX - minX) - (maxY - minY))) >= 50){
                        totalCards = 2
                    }
                        //只有一張卡片或兩張卡片為對角排列, 用單張卡片寬度概略像素數判斷卡片數量
                    else{
                        let XRange = maxX - minX
                        let XThreshold = 120
                        if(XRange >= XThreshold){
                            totalCards = 2
                        }
                        else{
                            totalCards = 1
                        }
                    }
                    if(blueCount >= 1000 && purpleCount <= 300){
                        cardColor = "Blue"
                    }
                    if(purpleCount >= 1000 && blueCount <= 300){
                        cardColor = "Purple"
                    }
                }
                
                //只取數字部分pixel做判斷, 忽略邊緣方框
                centerX = (minX + maxX)/2
                centerY = (minY + maxY)/2
                let edgeThreshold = 10
                //單張影像
                if(totalCards == 1 && (minY + edgeThreshold < centerY) && (minX + edgeThreshold < centerX) && (centerY < maxY - edgeThreshold) && (centerX < maxX - edgeThreshold)){
                    
                    var numberHorizontalArr = [Int](repeating:0, count:height)
                    var numberVerticalArr = [Int](repeating:0, count:width)
                    var numberMinX = 0
                    var numberMaxX = 0
                    var numberMinY = 0
                    var numberMaxY = 0
                    var upRightCount = 0
                    var firstUpRightX = 0
                    var lastDownRightX = 0
                    
                    var downRightCount = 0
                    for row in 1 ..< height - 1 {
                        for col in 1 ..< width - 1 {
                            let offset = Int((height-1-row) * width + col)
                            if(Int(pixels[offset].red) == 0){
                                let n1 = Int(pixels[((row-1) * width + (col-1))].red)
                                let n2 = Int(pixels[((row-1) * width + col)].red)
                                let n3 = Int(pixels[((row-1) * width + (col+1))].red)
                                let n4 = Int(pixels[(row * width + (col-1))].red)
                                let n5 = Int(pixels[(row * width + (col+1))].red)
                                let n6 = Int(pixels[((row+1) * width + (col-1))].red)
                                let n7 = Int(pixels[((row+1) * width + col)].red)
                                let n8 = Int(pixels[((row+1) * width + (col+1))].red)
                                
                                if (n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 != 0){
                                    numberHorizontalArr[height-1-row] += 1
                                    numberVerticalArr[col] += 1
                                    if(numberVerticalArr[col] == 1 && col < centerX && row > centerY + 3){
                                        upRightCount += 1
                                        if(firstUpRightX == 0){
                                            firstUpRightX = col
                                        }
                                    }
                                    if(numberVerticalArr[col] == 1 && col > centerX && row > centerY + 3){
                                        downRightCount += 1
                                        lastDownRightX = col
                                    }
                                }
                            }
                        }
                    }
                    var numberVerticalArrRight = [Int](repeating:0, count:width)
                    var upLeftCount = 0
                    var downLeftCount = 0
                    for row in 1 ..< height - 1 {
                        for col in 1 ..< width - 1 {
                            let offset = Int(row * width + col)
                            if(Int(pixels[offset].red) == 0){
                                let n1 = Int(pixels[((row-1) * width + (col-1))].red)
                                let n2 = Int(pixels[((row-1) * width + col)].red)
                                let n3 = Int(pixels[((row-1) * width + (col+1))].red)
                                let n4 = Int(pixels[(row * width + (col-1))].red)
                                let n5 = Int(pixels[(row * width + (col+1))].red)
                                let n6 = Int(pixels[((row+1) * width + (col-1))].red)
                                let n7 = Int(pixels[((row+1) * width + col)].red)
                                let n8 = Int(pixels[((row+1) * width + (col+1))].red)
                                
                                if (n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 != 0){
                                    numberVerticalArrRight[col] += 1
                                    if(numberVerticalArrRight[col] == 1 && col < centerX && height - row - 1 < centerY - 3){
                                        upLeftCount += 1
                                    }
                                    if(numberVerticalArrRight[col] == 1 && col > centerX && height - row - 1 < centerY - 3){
                                        downLeftCount += 1
                                    }
                                }
                            }
                        }
                    }
                    
                    for row in 0 ..< numberHorizontalArr.count {
                        if(numberHorizontalArr[row] != 0){
                            if(numberMinY == 0){
                                numberMinY = row
                            }
                            numberMaxY = row
                        }
                    }
                    for col in 0 ..< numberVerticalArr.count {
                        if(numberVerticalArr[col] != 0){
                            if(numberMinX == 0){
                                numberMinX = col
                            }
                            numberMaxX = col
                        }
                    }
                    
                    var zeroVerticalCount = 0
                    for col in numberMinX ..< numberMaxX {
                        if(numberVerticalArr[col] == 0){
                            zeroVerticalCount += 1
                        }
                    }
                    
                    var cardNumberText = "None"
                    
                    let n5 = Int((height - centerY - 1) * width + centerX)
                    let n8 = Int((height - centerY) * width + centerX)
                    let n11 = Int((height - centerY + 1) * width + centerX)
                    
                    if(numberMaxY - numberMinY < 25){
                        if(Int(pixels[n5].green) == 0){
                            cardNumberText = "1"
                        }
                    }
                    
                    if(zeroVerticalCount > 0 && upLeftCount == 0){
                        if(Int(pixels[n5].green) == 0 || Int(pixels[n8].green) == 0 || Int(pixels[n11].green) == 0){
                            cardNumberText = "9"
                        }
                        else{
                            cardNumberText = "6"
                        }
                    }
                    
                    if(upRightCount > 0  && upLeftCount == 0){
                        if(upRightCount >= 2){
                            if(downRightCount >= 1 && firstUpRightX - numberMinX <= 10){
                                cardNumberText = "4"
                            }
                            else if(upRightCount >= 4 && firstUpRightX - numberMinX >= 15){
                                cardNumberText = "2"
                            }
                        }
                    }
                    
                    if(upLeftCount >= 2){
                        if(downRightCount >= 4 && numberMaxX - lastDownRightX >= 10){
                            cardNumberText = "5"
                            print(numberHorizontalArr[height - centerY - 1])
                        }
                    }
                    else{
                        if(downRightCount >= 4 && numberMaxX - lastDownRightX >= 10){
                            cardNumberText = "3"
                            print(numberHorizontalArr[height - centerY - 1])
                        }
                    }
                    
                    if(downLeftCount >= 3){
                        if(downRightCount == 0){
                            cardNumberText = "7"
                        }
                    }
                    
                    if(upLeftCount == 0 && upRightCount == 0 && downLeftCount == 0 && downRightCount == 0 && zeroVerticalCount == 0 && numberMaxY - numberMinY >= 26){
                        if(Int(pixels[n5].green) == 0 || Int(pixels[n8].green) == 0 || Int(pixels[n11].green) == 0){
                            cardNumberText = "8"
                        }
                        else{
                            cardNumberText = "0"
                        }
                    }
                    
                    if(cardNumberText != "None"){
                        cardNumber = cardNumberText
                    }
                    else{
                        cardNumber = "Reading..."
                    }
                }
                else{
                    cardNumber = "None"
                }
                //分別計算總像素(比例), 跟0-9範本相比, 計算相似度
                
                //兩張以上
                //切出兩張影像, 分別再切出4個區塊
                if(totalCards == 2){
                    print(String(purpleCount + blueCount))
                    cardNumber = "None"
                }
                //分別計算總像素(比例), 跟0-9範本相比, 計算相似度
                
                coordsOfCenter = "(" + String(centerY) + ", " + String(centerX) + ")"
            }
            else{
                coordsOfCenter = "Not Exist"
                cardColor = "None"
                totalCards = 0
                cardNumber = "None"
            }
        }
        // return the image
        let outputImage = context.makeImage()!
        return (nowMode, cardColor, coordsOfCenter, totalCards, cardNumber,setTempBasicFrame, tempBasicFrame, setBasicFrame, basicFrame, passFrameMin, passFrameCounter)
    }
    func centerMove(centerX:Int, centerY:Int, halfImgWidth:Int, halfImgHeight:Int, translateAngle:Int, minXCoord: [Int], minYCoord: [Int], width:Int, height:Int) -> (Int, Int)? {
        
        let xCosTheta = Double(centerX - halfImgWidth) * cos(Double(translateAngle) * M_PI / 180)
        let ySinTheta = Double(centerY - halfImgHeight) * sin(Double(translateAngle) * M_PI / 180)
        let xSinTheta = Double(centerX - halfImgWidth) * sin(Double(translateAngle) * M_PI / 180)
        let yCosTheta = Double(centerY - halfImgHeight) * cos(Double(translateAngle) * M_PI / 180)
        
        var newCol = 0
        var newRow = 0
        if(Swift.abs(minXCoord[0] - minYCoord[0]) > Swift.abs(minXCoord[1] - minYCoord[1])){
            newCol = Int(xCosTheta - ySinTheta)
            newRow = Int(xSinTheta + yCosTheta)
        }
        else if(Swift.abs(minXCoord[0] - minYCoord[0]) < Swift.abs(minXCoord[1] - minYCoord[1])){
            newCol = Int(xCosTheta + ySinTheta)
            newRow = Int(0 - xSinTheta + yCosTheta)
        }
        if(newCol >= width){
            newRow += Int(newCol / width)
            newCol += (0 - Int(width * Int(newCol / width)))
        }
        
        return (newCol - centerX, newRow - centerY)
    }
    struct Pixel: Equatable {
        private var rgba: UInt32
        
        var red: UInt8 {
            return UInt8((rgba >> 24) & 255)
        }
        
        var green: UInt8 {
            return UInt8((rgba >> 16) & 255)
        }
        
        var blue: UInt8 {
            return UInt8((rgba >> 8) & 255)
        }
        
        var alpha: UInt8 {
            return UInt8((rgba >> 0) & 255)
        }
        
        init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
            rgba = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
        }
        
        static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        static func ==(lhs: Pixel, rhs: Pixel) -> Bool {
            return lhs.rgba == rhs.rgba
        }
    }
    //輸入圖片陣列, 相減比對後取初始畫面
    func processInitView(myColor:Array<Int>, width:Int, height:Int) ->(setTempBasicFrame:Bool, tempBasicFrame:[Int], setBasicFrame:Bool, basicFrame:[Int], passFrameMin:Int, passFrameCounter:Int){
        let threshold = width * height * 10
        // set temp basic frame
        if(setTempBasicFrame == false){
            for row in 0 ..< height {
                for col in 0 ..< width {
                    let offset = Int(row * width + col)
                    tempBasicFrame.append(myColor[offset])
                }
            }
            setTempBasicFrame = true
        }
            // subtract new frame with temp basic frame ---> total difference
        else{
            var difference = 0
            for row in 0 ..< height {
                for col in 0 ..< width {
                    let offset = Int(row * width + col)
                    difference += Swift.abs(tempBasicFrame[offset] - myColor[offset])
                }
            }
            print ("Difference: \(difference)")
            // if diff < threshold ---> pass count++
            if(difference < threshold){
                passFrameCounter += 1
                print("Passed Frame Count: \(passFrameCounter)")
                // if pass count >= frameThreshold ---> set basic view
                if(passFrameCounter == passFrameMin){
                    basicFrame = tempBasicFrame
                    setBasicFrame = true
                    print ("Set Initial Frame Completed.")
                }
                
            }
                // if diff >= threshold ---> choose new temp basic frame
            else{
                passFrameCounter = 0
                setTempBasicFrame = false
                tempBasicFrame.removeAll()
            }
        }
        return (setTempBasicFrame:setTempBasicFrame, tempBasicFrame:tempBasicFrame, setBasicFrame:setBasicFrame, basicFrame:basicFrame, passFrameMin:passFrameMin, passFrameCounter:passFrameCounter)
    }
    //重新初始化背景
    func Restart()->(setTempBasicFrame:Bool, tempBasicFrame:[Int], setBasicFrame:Bool, basicFrame:[Int], passFrameMin:Int, passFrameCounter:Int){
        return (setTempBasicFrame:false, tempBasicFrame:[Int](), setBasicFrame:false, basicFrame:[Int](), passFrameMin:5, passFrameCounter:0)
    }
}


