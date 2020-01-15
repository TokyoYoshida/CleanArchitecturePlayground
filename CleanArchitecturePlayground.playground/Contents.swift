// 【Frameworks & Drivers】
// DB, UI
class SomeDB {
    static func executeQuery(sql: String, bindParam: [String]) {
        // Dummy ここで実際にユーザーを登録する
    }
}

class SomeUI {
    static func output(string: String){
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
        SomeUI.output(string: userName)
    }
}

// 【Application Business Rules】 アプリケーションのビジネスルール
// Use Cases ユースケースを表す
struct UserCreateInputData {
    var userName: String
}

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

struct UserCreateOutputData {
    var userName: String
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
