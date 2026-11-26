import GoogleMobileAds
import SwiftUI

struct AdMobNativeAdvancedView: View {
    @State private var isLoaded = false

    var body: some View {
        NativeAdViewContainer(isLoaded: $isLoaded)
            .frame(height: isLoaded ? 350 : 0)
            .animation(.easeOut(duration: 0.2), value: isLoaded)
            .clipped()
    }
}

private struct NativeAdViewContainer: UIViewRepresentable {
    @Binding var isLoaded: Bool

    func makeUIView(context: Context) -> NativeAdCardView {
        let view = NativeAdCardView()
        context.coordinator.adView = view
        context.coordinator.loadAd()
        return view
    }

    func updateUIView(_ uiView: NativeAdCardView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
    }

    final class Coordinator: NSObject, NativeAdLoaderDelegate {
        @Binding private var isLoaded: Bool
        weak var adView: NativeAdCardView?
        private var adLoader: AdLoader?

        init(isLoaded: Binding<Bool>) {
            _isLoaded = isLoaded
        }

        func loadAd() {
            let loader = AdLoader(
                adUnitID: AdMobConfiguration.nativeAdvancedAdUnitID,
                rootViewController: nil,
                adTypes: [.native],
                options: nil
            )
            loader.delegate = self
            adLoader = loader
            loader.load(Request())
        }

        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            guard let adView else { return }
            nativeAd.rootViewController = adView.window?.rootViewController
            adView.configure(with: nativeAd)
            isLoaded = true
        }

        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
#if DEBUG
            print("Native ad failed to load: \(error.localizedDescription)")
#endif
            isLoaded = false
        }
    }
}

private final class NativeAdCardView: NativeAdView {
    private let headlineLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let disclosureLabel = UILabel()
    private let iconImageView = UIImageView()
    private let media = MediaView()
    private let bodyLabel = UILabel()
    private let callToActionButton = UIButton(type: .system)
    private let choicesView = AdChoicesView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with nativeAd: NativeAd) {
        headlineLabel.text = nativeAd.headline
        advertiserLabel.text = nativeAd.advertiser
        bodyLabel.text = nativeAd.body
        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon == nil
        advertiserLabel.isHidden = nativeAd.advertiser == nil
        bodyLabel.isHidden = nativeAd.body == nil
        callToActionButton.isHidden = nativeAd.callToAction == nil
        media.mediaContent = nativeAd.mediaContent

        headlineView = headlineLabel
        advertiserView = advertiserLabel
        iconView = iconImageView
        bodyView = bodyLabel
        callToActionView = callToActionButton
        mediaView = media
        adChoicesView = choicesView
        self.nativeAd = nativeAd
    }

    private func buildLayout() {
        backgroundColor = UIColor.secondarySystemGroupedBackground
        layer.cornerRadius = 16
        clipsToBounds = true

        headlineLabel.font = .preferredFont(forTextStyle: .headline)
        headlineLabel.adjustsFontForContentSizeCategory = true
        headlineLabel.numberOfLines = 2

        advertiserLabel.font = .preferredFont(forTextStyle: .caption1)
        advertiserLabel.textColor = .secondaryLabel

        disclosureLabel.text = "広告"
        disclosureLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        disclosureLabel.textColor = .secondaryLabel
        disclosureLabel.backgroundColor = UIColor.tertiarySystemFill
        disclosureLabel.textAlignment = .center
        disclosureLabel.layer.cornerRadius = 4
        disclosureLabel.clipsToBounds = true

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true

        media.contentMode = .scaleAspectFill
        media.clipsToBounds = true
        media.layer.cornerRadius = 10

        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.adjustsFontForContentSizeCategory = true

        callToActionButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        callToActionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.cornerStyle = .medium
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14)
        callToActionButton.configuration = buttonConfiguration

        let advertiserRow = UIStackView(arrangedSubviews: [iconImageView, advertiserLabel, disclosureLabel])
        advertiserRow.axis = .horizontal
        advertiserRow.alignment = .center
        advertiserRow.spacing = 8
        advertiserRow.setCustomSpacing(0, after: advertiserLabel)

        let content = UIStackView(arrangedSubviews: [advertiserRow, headlineLabel, media, bodyLabel, callToActionButton])
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 8
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        disclosureLabel.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        callToActionButton.setContentHuggingPriority(.required, for: .vertical)
        media.heightAnchor.constraint(equalToConstant: 128).isActive = true

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            content.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),
            disclosureLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 34),
            disclosureLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
