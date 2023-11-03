``` mermaid
%%{init: {'theme': 'forest' } }%%
sequenceDiagram

    actor User
    participant MainActivity as <<View:UI制御>><br />MainActivity
    participant MainPresenter as <<Presenter:ビジネスロジック>><br />MainPresenter
    participant MainInteractor as <<Interactor:機能>><br />MainInteractor
    participant MainRouter as <<Router:画面遷移>><br />MainRouter

    note over User,MainRouter: 画面生成
    User ->> MainActivity  : アプリ起動。
    MainActivity ->> MainPresenter  : onCreate()
    note right of MainPresenter : DataStoreManager#readString()
    MainPresenter ->> MainInteractor  : readInitialSettings()
    note right of MainInteractor : DataStoreManager#readString()
    alt 前データが存在する
        MainInteractor  ->> MainPresenter : onReadInitialSettingsCompleted()
        MainPresenter  ->> MainActivity : setMainViewWithTime()
        MainActivity  ->> User : 前回のデータを引き継いだ\nホーム画面を表示する。
    else 前データが存在しない
        MainInteractor  ->> MainPresenter : onReadInitialSettingsFailed()
        MainPresenter  ->> MainActivity : setMainView()
        MainActivity  ->> User : ホーム画面を表示する。
    end

    note over User,MainRouter: メニュー表示
    User ->> MainActivity  : 縦三点ボタンをクリック。
    MainActivity  ->> User : メニューを表示させる。
    opt ライセンス情報
        User ->> MainActivity  : ライセンスメニューをクリック。
        MainActivity ->> MainPresenter  : onLicenseClicked()
        MainPresenter ->> MainRouter  : launchLicenseActivity()
        MainRouter  ->> User : ライセンス画面を表示させる。
    end
    opt プライバシーポリシー
        User ->> MainActivity  : プライバシーポリシーメニューをクリック。
        MainActivity ->> MainPresenter  : onPrivacyPolicyClicked()
        MainPresenter ->> MainRouter  : launchPrivacyPolicyActivity()
        MainRouter  ->> User : プライバシーポリシー画面を表示させる。
    end
    User ->> MainActivity  : メニューの外側をクリック。
    MainActivity  ->> User : メニューを閉じる。
```
