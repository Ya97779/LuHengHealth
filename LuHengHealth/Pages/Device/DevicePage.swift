//
//  DevicePage.swift
//  LuHengHeath
//  设备控制页面
//  Created by macios on 2025/7/16.
//

import SwiftUI
import AVFoundation
import CoreBluetooth

struct DevicePage: View {
    
    @EnvironmentObject var viewModel: BLEViewModel //环境中获取BLEViewModel
    
	@State private var showScanner: Bool = false //控制二维码扫描
    @State private var showBLEWindow = false // 控制蓝牙设备窗口的显示状态
    
	var body: some View {
        let bottomPadding: CGFloat = DeviceType.current == .iPad ? 300 : 100
		ZStack {
			// 背景图层
			Image("Appbackground")
				.resizable()
				.scaledToFill()
				.ignoresSafeArea()
			ScrollView(.vertical, showsIndicators: false) {
				VStack(spacing: 0) {
						VStack(spacing: 0) {
							// 顶部导航栏
							HStack {
								Text("控制中心")
									.font(.system(size: 28, weight: .bold))
									.foregroundColor(.black)
								Spacer()
								// 右侧图标
								HStack(spacing: 15) {
                                    Button(action: {  showBLEWindow = true }){
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 22))
                                            .foregroundColor(.black)
                                    }
                                    // 弹出蓝牙设备窗口
                                    .sheet(isPresented: $showBLEWindow) {
                                        BLEContentView()
                                            .presentationDetents([.large]) // 大尺寸显示
                                    }
									Button(action: { showScanner = true }) {
										Image(systemName: "qrcode.viewfinder")
											.font(.system(size: 22))
											.foregroundColor(.black)
									}
									.sheet(isPresented: $showScanner) {
										QRCodeScannerSheet { code in
											// 处理扫描结果
											print("Scanned QR: \(code)")
										}
									}
								}
							}
							.padding(.horizontal, 20)
							.padding(.top, topBarReservedPadding(6))
							
							// 设备信息卡片
							DeviceInfoCard()
								.padding(.horizontal, 20)
								.padding(.top, 30)
							
							Spacer()
					
					}
					
					
					VStack(spacing: 0) {
						// 商场区域
						VStack(spacing: 0) {
							// 商场标题
							HStack {
								Text("商场")
									.font(.system(size: 20, weight: .bold))
									.foregroundColor(.black)
								Spacer()
								Text("记录 >>")
									.font(.system(size: 14))
									.foregroundColor(.gray)
							}
							.padding(.horizontal, 20)
							.padding(.top, 30)
							
							// 商场卡片
							ShopCard()
								.padding(.horizontal, 20)
								.padding(.top, 20)
						}
						
						// 列表区域
						VStack(spacing: 0) {
							// 列表标题
							HStack {
								Text("列表")
									.font(.system(size: 20, weight: .bold))
									.foregroundColor(.black)
								Spacer()
							}
							.padding(.horizontal, 20)
							.padding(.top, 40)
							
							// 列表项

                                VStack(spacing: 12) {
                                    CustomRow(
                                        icon: "link",
                                        iconColor: .orange,
                                        title: "连接",
                                        subtitle: "点击进行设备与app连接",
                                        destination: BLEContentView()
                                    )
                                    
                                    CustomRow(
                                        icon: "dot.radiowaves.up.forward",
                                        iconColor: .orange,
                                        title: "多设备共连",
                                        subtitle: "多个设备同连，可查看多个数据",
                                        destination:Text("wwwww")
                                    )
                                    
                                    CustomRow(
                                        icon: "arrow.triangle.2.circlepath",
                                        iconColor: .orange,
                                        title: "转变",
                                        subtitle: "调整设备模式，如儿童模式",
                                        destination: HomePage()
                                    )
                                    
                                    CustomRow(
                                        icon: "app.connected.to.app.below.fill",
                                        iconColor: .orange,
                                        title: "应用",
                                        subtitle: "应用效果之类的",
                                        destination: HomePage()
                                    )
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
						}
					}
					.padding(.bottom, 20) // 为底部导航栏留空间
				}
			}
			.safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarReservedHeight()  + bottomPadding)
			}
			.background(Color.clear)
			
				}
			}
		}
   
// MARK:  - 组件
// 设备信息卡片
struct DeviceInfoCard: View {
    
    
    @EnvironmentObject var viewModel: BLEViewModel
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // 左侧设备图片
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(red: 0.94, green: 0.78, blue: 0.4))
                    .frame(width: 100, height: 100)
                
                // 右侧设备信息
                VStack(alignment: .leading, spacing: 8) {
                    // 设备名称
                    Text("设备名称：" + (viewModel.connectedDevices.first?.name ?? "未找到"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    // 连接状态和电量
                    HStack(spacing: 8) {
                        Text(viewModel.connectedDevices.first?.name != nil ? "设备已连接" : "设备未连接")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Text("|")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Text("电量\(viewModel.batteryVoltage ?? 0)%")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        if let firmwareVersion = viewModel.firmwareVersion {
                            Text("|")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            Text("v\(firmwareVersion / 10).\(firmwareVersion % 10)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 信息同步标签
                    Text(viewModel.connectedDevices.first?.name != nil ?"信息同步": "信息未同步")
                        .font(.system(size: 12))
                        .foregroundColor(.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            
            // 多设备共链
            HStack {
                Text("多设备共连数量: \(viewModel.connectedDevices.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.top, 12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(15)
    }
}

// 商场卡片轮播
struct ShopCard: View {
    @State private var currentIndex = 1 // 当前选中的卡片索引（从1开始，与原型图一致）
    
    // 模拟商品数据
    let shopItems = [
        ShopItem(discount: "8折", title: "点击购买此商品1 >>", color: Color(red: 0.94, green: 0.78, blue: 0.4)),
        ShopItem(discount: "9折", title: "点击购买此商品2 >>", color: Color(red: 0.94, green: 0.78, blue: 0.4)),
        ShopItem(discount: "7折", title: "点击购买此商品3 >>", color: Color(red: 0.94, green: 0.78, blue: 0.4))
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // 可滑动的商品卡片
            TabView(selection: $currentIndex) {
                ForEach(0..<shopItems.count, id: \.self) { index in
                    ShopItemCard(item: shopItems[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 120)
            .animation(.easeInOut(duration: 0.3), value: currentIndex)
            
            // 自定义指示器
            HStack(spacing: 8) {
                ForEach(0..<shopItems.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
        }
    }
}

// 商品数据模型
struct ShopItem {
    let discount: String
    let title: String
    let color: Color
}

// 单个商品卡片
struct ShopItemCard: View {
    let item: ShopItem
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧折扣图标和文字
            HStack(spacing: 8) {
                // 折扣图标
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 2)
                    
                    Image(systemName: "tag.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                
                Text(item.title)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            // 右侧商品图片
            RoundedRectangle(cornerRadius: 15)
                .fill(item.color)
                .frame(width: 80, height: 80)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// 列表项组件
struct CustomRow<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let destination: Destination   // 跳转的目标视图，由泛型定义

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                // 左侧图标
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // 中间文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 右侧箭头
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain) // 去掉 NavigationLink 默认的高亮
    }
}




#Preview {
    DevicePage()
}

