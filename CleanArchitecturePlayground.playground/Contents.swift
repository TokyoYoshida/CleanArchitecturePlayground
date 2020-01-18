// 【Frameworks & Drivers】アプリケーションフレームワークやドライバなど実装の詳細にあたる部分

// DB ORMやDAOなどDBとのやり取りをするAPI。このサンプルではモック。
class SomeDB {
    static func executeQuery(sql: String, bindParam: [String]) {
        // Dummy ここで実際にユーザーを登録する
    }
}

// UI　UIKitやRailsの表示部分など画面表示をするためのAPI。このサンプルではモック
class SomeUI {
    let viewModel = UserCreateViewModel(userName: "")

    func start(){
        viewModel
    }

    func output(string: String){
        print("output = \(string)")
    }
}



// 【Interface Adapters】Application Business RulesとFrameworks & Driversの型の相互変換

// Controllers 入力をUserCaseのために変換する（入力のための変換）
class UserController {
    var userCreateUseCase: UserCreateUseCaseInterface
    
    init(userCreateUseCase: UserCreateUseCaseInterface) {
        self.userCreateUseCase = userCreateUseCase
    }
    
    func createUser(userName: String) {
        let input = UserCreateInputData(userName: userName)
        userCreateUseCase.handle(input: input)
    }
}

// GateWays Frameworks & Driversからのデータを抽象化する
protocol UserRepositoryInterface {
    func save(user: User)
}

class UserRepository: UserRepositoryInterface {
    func save(user: User) {
        SomeDB.executeQuery(
            sql: "REPLACE INTO USER (USER_NAME) VALUES (?) ",
            bindParam: [user.userName]
        )
    }
}

// Presenters データをViewに適した加工する（出力のための変換）
protocol UserCreatePresenterInterface {
    func complete(output: UserCreateOutputData)
}

class UserCreatePresenter: UserCreatePresenterInterface {
    func complete(output: UserCreateOutputData) {
        let userName = output.userName
        UserCreateViewModel(userName: userName)
    }
}

class UserCreateViewModel {
    var userName: String
    init(userName: String) {
        self.userName = userName + "さん"
    }
    
    func bind() {
        
    }
}

// 【Application Business Rules】 アプリケーションのビジネスルール

// UseCaseと上位層との遣り取りをするためのオブジェクト
// このような境界を超えるデータはなるべく簡素にする。メソッドの引数やハッシュを用いても良い。なるべく内側の円にとって便利な形式であれば良い。
struct UserCreateInputData {
    var userName: String
}

struct UserCreateOutputData {
    var userName: String
}

// Use Cases ユースケースを表す
protocol UserCreateUseCaseInterface {
    func handle(input: UserCreateInputData)
}

class UserCreateInteractor: UserCreateUseCaseInterface{
    var userRepo: UserRepository
    var presenter: UserCreatePresenter
    init(userRepo: UserRepository, presenter: UserCreatePresenter) {
        self.userRepo = userRepo
        self.presenter = presenter
    }

    func handle(input: UserCreateInputData) {
        let userName = input.userName
        
        let user = User(userName: userName)
        userRepo.save(user: user)
        
        let output = UserCreateOutputData(userName: user.userName)
        presenter.complete(output: output)
    }
}

// 【Enterprise Business Rules】 ドメイン層
// Entities ビジネスルールをカプセル化したもの
struct User {
    var userName: String
}

// Entry Point　このサンプルの実行開始ポイント
let userRepo = UserRepository()
let presenter = UserCreatePresenter()
let useCase = UserCreateInteractor(userRepo: userRepo, presenter: presenter)
let controller = UserController(userCreateUseCase: useCase)

controller.createUser(userName: "test user")
