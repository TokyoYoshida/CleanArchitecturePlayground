// 【Frameworks & Drivers】アプリケーションフレームワークやドライバなど実装の詳細にあたる部分

// DB ORMやDAOなどDBとのやり取りをするAPI。このサンプルでは何もしない。
class SomeDB {
    static func executeQuery(sql: String, bindParam: [String]) {
        // Dummy ここで実際にユーザーを登録する
    }
}

// UI　UIKitやRailsの表示部分など画面表示をするためのAPI。
class SomeView {
    var userController: UserController
    var viewModel: UserCreateViewModel

    init(userController: UserController, viewModel: UserCreateViewModel) {
        self.userController = userController
        self.viewModel = viewModel
        self.viewModel.bind { userName in
            print("登録：" + userName + "さん")
        }
    }
    
    func start(){
        userController.createUser(userName: "test user")
    }
}

// 【Interface Adapters】Application Business RulesとFrameworks & Driversの型の相互変換

// Controllers 入力をUserCaseのために変換する（入力のための変換）
class UserController {
    var userCreateUseCase: UserCreateUseCaseInputPort
    
    init(userCreateUseCase: UserCreateUseCaseInputPort) {
        self.userCreateUseCase = userCreateUseCase
    }
    
    func createUser(userName: String) {
        let input = UserCreateInputData(userName: userName)
        userCreateUseCase.handle(input: input)
    }
}

// GateWays Frameworks & Driversからのデータを抽象化する
class UserDataAccess: UserDataAccessInterface {
    func save(user: UserEntity) {
        SomeDB.executeQuery(
            sql: "REPLACE INTO USER (USER_NAME) VALUES (?) ",
            bindParam: [user.userName]
        )
    }
}

// Presenters データをViewに適した加工する（出力のための変換）
class UserCreatePresenter: UserCreateUseCaseOutputPort {
    var viewModel: UserCreateViewModel

    init(viewModel: UserCreateViewModel) {
        self.viewModel = viewModel
    }

    func complete(output: UserCreateOutputData) {
        let userName = output.userName
        self.viewModel.update(userName: userName)
    }
}

class UserCreateViewModel {
    typealias CallBackType = (String)->Void
    var userName: String
    var callBack: CallBackType?
    init(userName: String) {
        self.userName = userName
    }
    
    func bind(callBack: @escaping CallBackType) {
        self.callBack = callBack
    }
     
    func update(userName: String) {
        self.userName = userName
        self.callBack?(userName)
    }
}

// 【Application Business Rules】 アプリケーションのビジネスルール

// UseCaseと上位層との遣り取りをするためのオブジェクト
protocol UserDataAccessInterface {
    func save(user: UserEntity)
}

protocol UserCreateUseCaseOutputPort { // Output Boundaryともいう
    func complete(output: UserCreateOutputData)
}

struct UserCreateInputData {
    var userName: String
}

struct UserCreateOutputData {
    var userName: String
}

// Use Cases ユースケースを表す
protocol UserCreateUseCaseInputPort {  // Input Boundaryともいう
    func handle(input: UserCreateInputData)
}

class UserCreateInteractor: UserCreateUseCaseInputPort {
    var userDataAccess: UserDataAccess
    var presenter: UserCreateUseCaseOutputPort
    init(userDataAccess: UserDataAccess, presenter: UserCreateUseCaseOutputPort) {
        self.userDataAccess = userDataAccess
        self.presenter = presenter
    }

    func handle(input: UserCreateInputData) {
        let userName = input.userName
        
        let user = UserEntity(userName: userName)
        userDataAccess.save(user: user)
        
        let output = UserCreateOutputData(userName: user.userName)
        presenter.complete(output: output)
    }
}

// 【Enterprise Business Rules】 ドメイン層
// Entities ビジネスルールをカプセル化したもの
struct UserEntity {
    var userName: String
}

// Entry Point　このサンプルの実行開始ポイント
let viewModel = UserCreateViewModel(userName: "")
let userDataAccess = UserDataAccess()
let presenter = UserCreatePresenter(viewModel: viewModel)
let useCase = UserCreateInteractor(userDataAccess: userDataAccess, presenter: presenter)
let userController = UserController(userCreateUseCase: useCase)
var ui = SomeView(userController: userController, viewModel: viewModel)

ui.start()
