``` plantuml
@startuml

actor User
participant MainActivity <<View:UI制御>>
participant MainPresenter <<Presenter:ビジネスロジック>>
participant MainInteractor <<Interactor:機能>>
participant MainRouter <<Router:画面遷移>>

==画面生成==
User -> MainActivity : アプリ起動。
MainActivity -> MainPresenter : onCreate()
note right : DataStoreManager#readString()
MainPresenter -> MainInteractor : readInitialSettings()
note right : DataStoreManager#readString()
alt 前データが存在する
MainPresenter <-- MainInteractor : onReadInitialSettingsCompleted()
MainActivity <- MainPresenter : setMainViewWithTime()
User <- MainActivity : 前回のデータを引き継いだ\nホーム画面を表示する。
else 前データが存在しない
MainPresenter <-- MainInteractor : onReadInitialSettingsFailed()
MainActivity <- MainPresenter : setMainView()
User <- MainActivity : ホーム画面を表示する。
end

==メニュー表示==
User -> MainActivity : 縦三点ボタンをクリック。
User <- MainActivity : メニューを表示させる。
opt ライセンス情報
User -> MainActivity : ライセンスメニューをクリック。
MainActivity -> MainPresenter : onLicenseClicked()
MainPresenter -> MainRouter : launchLicenseActivity()
User <- MainRouter : ライセンス画面を表示させる。
end
opt プライバシーポリシー
User -> MainActivity : プライバシーポリシーメニューをクリック。
MainActivity -> MainPresenter : onPrivacyPolicyClicked()
MainPresenter -> MainRouter : launchPrivacyPolicyActivity()
User <- MainRouter : プライバシーポリシー画面を表示させる。
end
User -> MainActivity : メニューの外側をクリック。
User <- MainActivity : メニューを閉じる。
@enduml
```
