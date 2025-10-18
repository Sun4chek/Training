import UIKit

final class OnboardingViewController: UIPageViewController,
                                      UIPageViewControllerDataSource,
                                      UIPageViewControllerDelegate {

    // Колбэк, чтобы TabBarController знал, что онбординг закончен
    var onFinish: (() -> Void)?

    
    init() {
        // Меняем стиль трансляции на scroll вместо pageCurl
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    lazy var pages: [UIViewController] = {
        let first = createPageViewController(
            with: "onbordingFirst",
            text: "Отслеживайте только то, что хотите"
        )

        let second = createPageViewController(
            with: "onbordingSecond",
            text: "Даже если это не литры воды и йога"
        )

        return [first, second]
    }()

    // MARK: - UI Elements

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = pages.count
        control.currentPage = 0
        control.currentPageIndicatorTintColor = UIColor(resource: .ypBlack)
        control.pageIndicatorTintColor = UIColor(resource: .ypGrey)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Вот это технологии!", for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 16)
        button.backgroundColor = UIColor(resource: .ypBlack)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: false, completion: nil)
        }

        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(pageControl)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -84),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 335),
            nextButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Page Creation

    private func createPageViewController(with imageName: String, text: String) -> UIViewController {
        let vc = UIViewController()
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.textColor = UIColor(resource: .ypBlack)
        label.font = UIFont(name: "SFProText-Bold", size: 32)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(imageView)
        vc.view.addSubview(label)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),

            label.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: -304),
            label.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -16)
        ])

        vc.view.sendSubviewToBack(imageView)
        return vc
    }

    // MARK: - Navigation Logic

    @objc private func nextButtonTapped() {
        finishOnboarding()
    }

    private func finishOnboarding() {
        UserDefaultsManager.shared.hasSeenOnboarding = true
        onFinish?() // сообщаем TabBarController, что можно закрыть экран
    }

    // MARK: - PageViewController DataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let previous = index - 1
        return previous >= 0 ? pages[previous] : nil // ТОЛЬКО если есть предыдущая страница
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let next = index + 1
        return next < pages.count ? pages[next] : nil // ТОЛЬКО если есть следующая страница
    }

    // MARK: - Delegate

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentVC)
        else { return }
        pageControl.currentPage = currentIndex
    }
}
