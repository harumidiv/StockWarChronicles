//
//  AdMobConfiguration.swift
//  StockWarChronicles
//

enum AdMobConfiguration {
    static var bannerAdUnitID: String {
#if DEBUG
        // Google-provided iOS banner test ad unit ID.
        return "ca-app-pub-3940256099942544/2435281174"
#else
        return "ca-app-pub-8522231452310619/6089502791"
#endif
    }

    static var rewardedAdUnitID: String {
#if DEBUG
        // Google-provided iOS rewarded test ad unit ID.
        return "ca-app-pub-3940256099942544/1712485313"
#else
        return "ca-app-pub-8522231452310619/1197277925"
#endif
    }
}
