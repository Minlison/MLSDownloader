# MLSDownloader
###m3u8下载和普通文件下载集成为一个下载器，使用block回调方法
!目前版本V1.0.0功能

修改功能1.0.2版本
1.添加m3u8文件播放server
2.全部使用libCurl下载

##在启动方法中执行下面代码

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 

{
        
        MLSDownloaderSingleton.autoResume = YES;
        MLSDownloaderSingleton.allowBackgroundDownload = NO;
        MLSDownloaderSingleton.onlyUseWifi = YES;
        
        
	return YES;
	
}
