pragma solidity ^0.4.17;

/**
 * @title Ownable
 * @dev Вспомогательынй контракт. Позволяет запомнить владельца контракта, передать права
 * владения, а так же содержит модификатор позволяющий функциям выполняться только
 * от имени владельца контракта.
 */
contract Ownable {
    //Владелец контракта
    address public owner;

    /**
    * @dev Модификатор, вызывающий исключение при вызове функции кем-либо,
    * кроме владельца контракта
    */
    modifier onlyOwner() {
        require(msg.sender == owner); 
        _;
    }

    /** 
    * @dev Собственный конструктор устанавливает первоначальным владельцем контракта 
    * учётную запись отправителя
    */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
    * @dev Позволяет передать управление контрактом новому владельцу. Выполнятеся 
    * только от лица владельца.
    * @param newOwner - адрес того, куму передаётся контракт
    */
    function transferOwnership(address newOwner) public onlyOwner {
        //Если передан не пустой адрес
        if (newOwner != address(0)) {
            //Меняем владельца
            owner = newOwner;
        }
    }
}


/**
 * @title Authorizable
 * @dev Вспомогательный контракт, содержащий список авторизованных лиц, а также
 * функцию добавления адресов в этот список. Содержит модификатор, позволяющий
 * выполнять функции иолько лицам из списка. 
 * 
 * ABI
 * [{"constant":true,"inputs":[{"name":"authorizerIndex","type":"uint256"}],"name":"getAuthorizer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_addr","type":"address"}],"name":"addAuthorized","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"}],"name":"isAuthorized","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"}]
 */
contract Authorizable {
    //Массив пользователей
    address[] private authorizers;
    //Id авторизуемого в массиве пользователей
    mapping(address => uint) private authorizerIndex;

    /**
    * @dev Модификатор, запрещающий выполнение функции кому-либо, кроме авторизованного лица
    */
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

    /**
    * @dev Конструктор авторизующий отправителя сообщения
    */
    function Authorizable() public {
        /*
        Похоже, что этот норкоман тупо не использует 0 элемент массива.
        */
        //Ставим длинну массива пользователей в 2 
        authorizers.length = 2;
        //И записываем первым пользователем человека запустившего контракт
        authorizers[1] = msg.sender;
        //И записываем id пользователя
        authorizerIndex[msg.sender] = 1;
    }

    /**
    * @dev Функция, для получения адреса авторизуемого по его id
    * @param _authorizerIndex id авторизующегося, чей адрес будет получен
    * @return Адрес авторизующегося.
    */
    function getAuthorizer(uint _authorizerIndex) external constant returns(address) {
        //Возврат адреса
        return address(authorizers[_authorizerIndex + 1]);
    }

    /**
    * @dev Функция, проверяющая, существует-ли банный адрес в массиве авторизовавшихся
    * @param _addr адрес, для проверки авторизовавшихся
    * @return boolean Флаг. Возвращает True, если человек есть в массиве авторизовавшихся
    */
    function isAuthorized(address _addr) public constant returns(bool) {
        return authorizerIndex[_addr] > 0;
    }

    /**
    * @dev Функция добавления нового авторизовавшегося в массив. Доступна для выполнения только авторизованным пользователям.
    * @param _addr адрес нового авторизовывающегося
    */
    function addAuthorized(address _addr) external onlyAuthorized {
        //Записываем новый id авторизовавшегося
        authorizerIndex[_addr] = authorizers.length;
        //Увеличиваем размер массива
        authorizers.length++;
        //Записываем нового авторизовавшегося
        authorizers[authorizers.length - 1] = _addr;
    }
}


/**
 * @title Обменный курс
 * @dev Контракт, реализующий хранение и использование курсов токенов.
 * ABI
 * [{"constant":false,"inputs":[{"name":"_symbol","type":"string"},{"name":"_rate","type":"uint256"}],"name":"updateRate","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"data","type":"uint256[]"}],"name":"updateRates","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_symbol","type":"string"}],"name":"getRate","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"bytes32"}],"name":"rates","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"anonymous":false,"inputs":[{"indexed":false,"name":"timestamp","type":"uint256"},{"indexed":false,"name":"symbol","type":"bytes32"},{"indexed":false,"name":"rate","type":"uint256"}],"name":"RateUpdated","type":"event"}]
 */
contract ExchangeRate is Ownable {
    //Обработчик события обновления курса 
    event RateUpdated(uint timestamp, bytes32 symbol, uint rate);
    //Список курсов
    mapping(bytes32 => uint) public rates;

    /**
    * @dev Позволяет текущему владельцу обновить единую ставку. Может быть вызвана только владельцем контракта.
    * @param _symbol Символ, который нужно обновить.
    * @param _rate Стоимость символа в Ether.
    */
    function updateRate(string _symbol, uint _rate) public onlyOwner {
        //Записываем новую стоимость, для указанного символа
        rates[keccak256(_symbol)] = _rate;
        //Вызываем ивент, возвращающий время, хеш символа и его обновлённую стоимость
        RateUpdated(now, keccak256(_symbol), _rate);
    }

    /**
    * @dev Позволяет текущему владельцу обновить несколько ставок. Может быть вызвана только владельцем контракта.
    * @param data массив, чередующий keccak256 хеши символов, и соответствующую им стоимость.
    */
    function updateRates(uint[] data) public onlyOwner {
        //Если массив имеет нечётное количество элементов - выходим
        require(data.length % 2 == 0);
        //Проходимся по полученному массиву данных
        uint i = 0;
        while (i < data.length / 2) {
            //Получаем символ (первый элемент пары)
            bytes32 symbol = bytes32(data[i * 2]);
            //Получаем ставку (второй элемент пары)
            uint rate = data[i * 2 + 1];
            //Записываем новую ставку
            rates[symbol] = rate;
            //Вызываем ивент, возвращающий время, хеш символа и его обновлённую стоимость
            RateUpdated(now, symbol, rate);
            //Увеличиваем счётчик
            i++;
        }
    }

    /**
    * @dev Позволяет любому считать текущую ставку символа.
    * @param _symbol Символ, ставку которого считываем
    */
    function getRate(string _symbol) public constant returns(uint) {
        return rates[keccak256(_symbol)];
    }
}


/**
 * @dev Математические операции, с проверками безопасности
 */
library SafeMath {
    // Операция безопасного умножения
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        // Вызывает исключение, если C делённое на A не равно B,
        // там ещё проверка деления на ноль сразу же
        assert(a == 0 || c / a == b);
        return c;
    }

    // Операция безопасного деления
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // В новой версии это исключение вызывается автоматом
        uint c = a / b;
        // assert(a == b * c + a % b); // Нет случаев, когда это исключение выполнится
        return c;
    }

    // Операция безопасного вычитания
    function sub(uint a, uint b) internal pure returns (uint) {
        // У нас доступны только положительные целые числа, значит А должно быть больше B. 
        // 0, судя по всему тоже возвращать нельзя.
        assert(b <= a);
        return a - b;
    }

    // Операция безопасного сложения
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        //Короче говоря, проверка того, что B не был отрицательным О_о.
        assert(c >= a);
        return c;
    }

    // Операция безопасной проверки какое число больше
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    // Операция безопасной проверки какое число меньше
    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    // Операция безопасной проверки какое число больше
    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    // Операция безопасной проверки какое число больше
    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title ERC20Basic
 * @dev Базовая версия интерфейса ERC20
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    //Переменная с общим количеством выпущенных токенов
    uint public totalSupply;
    //Функция получения баланса пользователя
    function balanceOf(address who) public constant returns (uint);
    //Функция отправки токенов пользователю
    function transfer(address to, uint value) public;
    //Событие, которое вызывается при отправке токенов
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    //Функция проверки доступа адреса к отправке
    function allowance(address owner, address spender) public constant returns (uint);
    //Функция передачи чего-то от одного адреса к другому
    function transferFrom(address from, address to, uint value) public;
    //Функция подтверждения доставки
    function approve(address spender, uint value) public;
    //Событие подтверждения доставки
    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Базовый токен
 * @dev Базовая версия стандартного токена, без проверок
 */
contract BasicToken is ERC20Basic {
    //Ссылка на контракт безопасной математики
    using SafeMath for uint;

    //Список балансов пользователей
    mapping(address => uint) public balances;

    /**
    * @dev Фикс, для атаки короткими адресами, в ERC20.
    * Не позволяет запукать функцию, если адрес отправляющего меньше
    * Определённого размера + 4.
    */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    /**
    * @dev Отправка токенов указанному адресу, с фиксом атаки адресами, короче 64 символов.
    * @param _to Адрес, на который отправляем токены.
    * @param _value Сумма, для отправки.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        //Снимаем с баланса отправляющего сумму платежа
        balances[msg.sender] = balances[msg.sender].sub(_value);
        //Прибавляем к балансу получателя сумму платежа
        balances[_to] = balances[_to].add(_value);
        //Вызываем событие, уведомляющее об отправке платежа
        Transfer(msg.sender, _to, _value);
    }

    /**
    * @dev Получаем баланс, указанного адреса
    * @param _owner Адрес, чей баланс узнаём. 
    * @return Сумма баланса, на указанном адресе.
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    /**
    * @dev проверяем существование стедств, на балансе данного пользователя
    * @param _owner Адрес, чей баланс проверяем. 
    * @return False - если есть средства на счету пользователя
    */
    function isBalance(address _owner) public constant returns (bool) {
        return (balances[_owner] == 0);
    }
}

/**
 * @title Токен, созданный по стандарту ERC20
 *
 * @dev Реализация самого обычного токена
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
    // Так, тут срань. Короче говоря, эта хрень указывает, для каждого адреса,
    // список адресов, и сумму токенов, которую второй адрес может снять от имени первого.
    // Вроде так.
    mapping (address => mapping (address => uint)) private allowed;


    /**
    * @dev Отправка токенов от одного адреса к другому
    * @param _from Адрес, с которого вы хотите отправить токены
    * @param _to address Адрес ,которому вы хотите отправить токены
    * @param _value uint Сумма токенов, которую вы хотите отправить
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        // Получаем сумму токенов, которую вы можете отправить с адреса _from, 
        // от лица адреса отправителя сообщения 
        var _allowance = allowed[_from][msg.sender];

        // Проверка не нужна, потому что функция sub(_allowance, _value)
        // вызовет исключение, при попытке вычитания из меньшего большего.
        // if (_value > _allowance) throw;

        // Увеличиваем баланс принимающего
        balances[_to] = balances[_to].add(_value);
        // Уменьшаем баланс отправляющего
        balances[_from] = balances[_from].sub(_value);
        // Уменьшаем сумму, которую вы можем снять от лица отправителя с баланса отпарляющего
        allowed[_from][msg.sender] = _allowance.sub(_value);
        // Вызываем ивент отправки средств
        Transfer(_from, _to, _value);
    }

    /**
    * @dev Разрешаем указанному адресу отправлять указанную сумму токенов,
    *  от имени человека вызвавшего функцию.
    * @param _spender Адрес, которому разрешается отправлять средства.
    * @param _value Количество токенов, которое ему разрешено отправить.
    */
    function approve(address _spender, uint _value) public {

        // Чтобы изменить сумму утверждения, вам сначала надо уменьшить допустимое 
        // количество адресов до 0, вызвав `approve(_spender, 0)`, если только оно
        // уже не равно нулю, чтобы смягчить условия гонки, описанной здесь:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) 
            require(false); //Решение кривое, но мне влом щас думать, как переписать это условие на обратное

        // Устанавливаем сумму токенов, которую данный адрес может переслать другому,
        // от лица вызыввшего функцию
        allowed[msg.sender][_spender] = _value;
        // Вызываем ивент, сообщающий об этом
        Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Функция, возвращающая количество токенов, которое _spender может отправить
    * от лица _owner. 
    * @param _owner Адрес, от чьего имени будет отправка токенов.
    * @param _spender Адрес, который будет отправлять токены
    * @return Сумма токенов, доступная к отправке
    */
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Mintable token
 * @dev Разширение базового токена
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {

    //Структура, хранящая данные одного возврата
    struct Retreive {
        //Количество токенов, которое будет выкуплено
        uint retreiveCount;
        //Общее количестово токенов, которое должно быть на момент
        //начала данного обмена, учитывая все предыдущие обмены.
        uint fullCount;
        //Курс обмена токенов на wei, для данного обмена
        uint rate;
    }


    //Ивент, выполняющийся при отправке токенов
    event Mint(address indexed to, uint value);
    //Ивент, выполняющийся при завершении чеканки токена
    event MintFinished();

    //Флаг заврешения выпуска токенов
    bool public mintingFinished = false;
    //Общий запас токенов
    uint public totalSupply = 0;    

    //Флаг запуска обменов
    bool public exchangeStarted = false;
    //Список пользователей, которые ассоциированы с количеством обменов, которые были произведены
    mapping (address => uint) public returnEtherList;
    //Хранилище Ether, куда поступает весь Ether, который идёт на обмен
   // address returnTokenVault;
    //Общий список процедур обмена, которые проводились
    Retreive[] public retreiveList;
    
    // Адрес хранения командного баланса, куда поступят 7% от проданных токенов, 
    //и будут заморожены до начала возвратов. Возвраты, для этих адресов 
    //выполняться не будут.
    address public teamTokens;
    // Адрес хранения командного баланса, куда поступят 3% от проданных токенов.
    address public teamBountyTokens;

    //Ивент, вызываемый, при обмене токенов на Ether
    event ReturnCoin(uint count, uint cost);


    //Модификатор, не дающий выполнить функцию, если токенн завершён
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Модификатор, запрещающий перевод токенов с командного кошелька
    * до наступления фазы обмена. В данный момент - не используется.
    */
  /*  modifier isNotTeam(address sender) {
        //Человек, отправляющий токены не в команде, либо стадия обмена уже началась.
        require((sender != teamTokens) || (exchangeStarted));
        _;
    }*/


    /**
    * @dev Функция чеканки мятных токенов. Функция может быть вызвана только создателем.
    * @param _to Адрес, который получит токены.
    * @param _amount Количество токенов, которое будет создано
    * @return Возвращает логическое значение успешности операции
    */
    function mint(address _to, uint _amount) public onlyOwner canMint returns (bool) {
        //Пополняем общий запас токенов
        totalSupply = totalSupply.add(_amount);
    
        //Пополняем баланс человека, которому отправляем токены ими
        balances[_to] = balances[_to].add(_amount);
        

        //Вызываем ивент, уведомляющий о пополнении
        Mint(_to, _amount);
        //Возвращаем удачное завершение функции
        return true;
    }

    /**
    * @dev Функция остановки чеканки новых токенов. Может быть вызвана только создателем.
    * @return True, если выполнено успешно
    */
    function finishMinting() public onlyOwner returns (bool) {
        //Завершаем чеканку
        mintingFinished = true;
        //Вызываем ивент об этом 
        MintFinished();
        //Возвращаем удачное завершение функции
        return true;
    }

    //Всё это говно нужно выделить в отдельный контракт, но я, пока не придумал, как это лучше реализовать
     
    /**
    * @dev Позволяет владельцу указать адрес хранилища 'командных' токенов.
    * @param _teamTokens Новый адрес хранилища токенов
    */
    function setTeamTokens(address _teamTokens) public onlyOwner {
        teamTokens = _teamTokens;        
    }

    /**
    * @dev Позволяет владельцу указать адрес хранилища 'наградных командных' токенов.
    * @param _teamBountyTokens Новый адрес хранилища токенов
    */
    function setTeamBountyTokens(address _teamBountyTokens) public onlyOwner {
        teamBountyTokens = _teamBountyTokens;        
    }

    /**
    * @dev устанавливаем хранилище, куда будут поступать Ether, для обмена на токены
    * @param owner - адрес владельца хранилища
    */
   /* function setReturnTokenVault(address owner) public onlyOwner {
        returnTokenVault = owner;
    }*/

    /**
    * @dev Позволяет владельцу контракта внести сумму в Ether, которая будет возвращена
    * @param cost суммма, отправленная, для текущей операции обмена
    * @param rate курс обмена токенов на Ether
    */
    function returnTokens(uint cost, uint rate) public onlyOwner payable {       
        //Получаем количество токенов, которые будут обменяны в течение этой
        //процедуры обмена. Просто делим внесённую сумму, на курс обмена.
        uint tokens = cost.mul(rate).div(1 ether);
        //Получаем общее количество токенов, которое должно быть на данный
        //момент, с учётом всех предыдущих процедур обмена.
        uint maxCount;
        //Если, это первая процедура обмена
        if (retreiveList.length == 0) {
            //Просто записываем общее количество токенов
            maxCount = totalSupply;
        //В противном случае
        } else {
            //вычитаем из общего количества токенов, для прошлой процедуры обмена
            //сумму токенов, которая должна была пройти обмен
            uint id = retreiveList.length - 1;
            maxCount = retreiveList[id].fullCount - retreiveList[id].retreiveCount; 
        }

        // Отправляем эфир в хранилище, для обмена. 
        // В случае ошибки - все транзакции будут отменены.
       // returnTokenVault.transfer(msg.value);
/*Хранилище, судя по всему - идёт нахуй. Отправлять бабки я могу только с
внутреннего счёта контракта =( */

        //Записываем в массив данные текущего обмена
        addCost(maxCount, tokens, rate);                
        // Указываем, что обмены уже начались
        exchangeStarted = true;
        //Вызываем ивент, сигнализирующий об очередном этапе обмена коинов на Ether
        ReturnCoin(tokens, cost);
    }
    
    /**
    * @dev Добавляем в список процедур обмена новую
    * @param fullCount общее количество токенов, которое должно быть на данный момент
    * @param retreiveCount количество меняемых токенов, для данной процедуры обмена
    * @param rate курс обмена токенов на wei
    */
    function addCost(uint fullCount, uint retreiveCount, uint rate) private onlyOwner {     
        uint id = retreiveList.length;          
        //Увеличиваем размер массива
        retreiveList.length++;
        //Записываем значения, для текущей процедуры обмена
        retreiveList[id].fullCount = fullCount;
        retreiveList[id].retreiveCount = retreiveCount;
        retreiveList[id].rate = rate;
    }

    /**
    * @dev функция забирания Ether пользователем
    * @param user - пользователь, который хочет обмена
    */
    function getEther(address user) public { //isNotTeam(msg.sender)
        //Если обмены уже начались
        require(exchangeStarted);
        //Если токенов на счету данного пользователя нет - отменяем выполнение.
        require(!isBalance(user));        
        //Получаем id последней полученной стадии возврата
        uint id = returnEtherList[user];
        //Сумма, для возврата пользователю
        uint returnCost = 0;
        uint fullCount;     
        uint retreiveCount;   
        uint count;
        //Получаем общее количество стадий обмена
        uint countReturns = retreiveList.length;
        //Пока у пользователя есть токены, и мы не прошли все пропущенные им 
        //возвраты токенов 
        for (uint i = id; i < countReturns; i++) {
            //Если, к началу итерации у юзера нету 
            //бабок, то выходим из цикла
            if (isBalance(user))
                break;
            //Получаем общее количество меняемых токенов, и
            fullCount = retreiveList[i].fullCount;
            //общее количество токенов, для данной процедуры обмена
            retreiveCount = retreiveList[i].retreiveCount;
            //Умножаем число меняемых токенов на баланс пользователя и
            //делим на общее количество токенов, для данного обмена
            //тем самым, получая количество токенов, которое мы обменяем 
            //для данного пользователя, в зависимости от соотношения его
            //доли токенов к их общему количеству. 
            count = (retreiveCount * balances[user]) / fullCount;

            //Если, количество токенов у пользователя меньше, чем
            //Количество токенов на возврат
            if (balances[user] < count) {
                //То мы меняем все его оставшиеся токены
                count = balances[user];
            }
            //Увеличиваем сумму обмена на нужное количество токенов
            returnCost += count.mul(1 ether).div(retreiveList[i].rate);
            //Снимаем указанное количество токенов со счёта запросившего
            balances[user] -= count;
        }
        // Изменяем количество обменов у пользователя
        returnEtherList[user] = countReturns;
        // Отправляем эфир из хранилища пользователю, в обмен на токены
        user.transfer(returnCost);
    }

    /**
    * @dev Функция обмена всех токенов на Ether, по причине не сбора софткапа.
    * @param user - пользователь, запросивший возврат.
    * @param rate - текущий курс токена.
    */
    function returnEther(address user, uint rate) public /*isNotTeam(msg.sender)*/ canMint {
        //Если токенов на счету данного пользователя нет - отменяем выполнение.
        require(!isBalance(user));        
        //Получаем количество токенов у пользователя
        uint balance = balances[user];
        //Обнуляем баланс пользователя
        balances[user] = 0;
        //Получаем количество Ether, которое мы должны вернуть пользователю
        uint returnCost = balance.mul(rate).div(1 ether);
        // Отправляем эфир из хранилища пользователю, в обмен на токены
        user.transfer(returnCost);
    }
}


/**
 * @title PayToken
 * @dev Основной контракт токенов
 * 
 * ABI 
 * [{"constant":true,"inputs":[],"name":"mintingFinished","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"startTrading","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"mint","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"tradingStarted","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[],"name":"MintFinished","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]
 */
contract QSCCoin is MintableToken {
    //Название токена
    string public name = "Quality Service Coin";
    //Символ токена
    string public symbol = "QSC";
    //Дробность (количество знаков, после запятой).
    uint public decimals = 18;
    //Флаг запуска торгов
    bool public tradingStarted = false;

    /**
    * @dev Модификатор, запрещающий вызов функции, до начала торгов
    */
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }

    /**
    * @dev Позволяет создателю токена запустить торги. Доступно только для создателя токена.
    */
    function startTrading() public onlyOwner {
        tradingStarted = true;
    }
    

    /**
    * @dev Позволяет кому угодно передавать токены, после начала торгов
    * @param _to Адрес получателя токенов
    * @param _value КОличество передаваемых токенов
    */
    function transfer(address _to, uint _value) public hasStartedTrading { //isNotTeam(msg.sender)
        //В случае, если баланс пользователя на нуле, и обмены уже идут
        //этот пользователь будет получать возвраты начиная только с текущего
        
        if (!isBalance(_to) && exchangeStarted) {
            //Говорим, что обмены у него пойдут только со следующего
            returnEtherList[_to] = retreiveList.length;
        }
        /*
            Ключевое слово {super} даёт прямой доступ к родительскому договору
        */  
        //Вызывает функцию transfer от basicToken (как я понял). По сути у нас получилась обёртка.
        super.transfer(_to, _value);
    }

    /**
    * @dev Позволяет кому угодно отправлять токены, от имени _from
    * @param _from адрес, от чьего имени будут отправлены токены
    * @param _to Адрес, кому будут отправлены токены
    * @param _value сумма токенов, для отправки
    */
    function transferFrom(address _from, address _to, uint _value) public hasStartedTrading { //isNotTeam(msg.sender)
        //В случае, если баланс пользователя на нуле, и обмены уже идут
        //этот пользователь будет получать возвраты начиная только с текущего       
        if (!isBalance(_to) && exchangeStarted) {
            //Говорим, что обмены у него пойдут только со следующего
            returnEtherList[_to] = retreiveList.length;
        }
        //Вызывает функцию transferFrom от StandardToken (как я понял). По сути у нас получилась обёртка.
        super.transferFrom(_from, _to, _value);  
    }    
}

/**
* @dev Контракт, выполняющий рассчёты по бонусам предпродаж токенов
*/
contract SaleBonuses is Ownable {
    //Подключение библиотеки безопасной математики
    using SafeMath for uint;
    //Один токен, со всеми его нулями - 1000000000000000000
    //Верхний предел количества выпущенных токенов, при предпродаже
    uint public hardcapPreIco = 90000000000000000000000;
    //Верхний предел количества выпущенных на продажу токенов
    uint public hardcap = 883636000000000000000000;//2185183000000000000000000;
    //Минимальная сумма, которую нужно набрать
    uint public softCap = 465727000000000000000000;//500583000000000000000000;
    //Лимит коинов, которые будут розданы в баунти-программе
    uint public bountyCap = 15954000000000000000000;//38562000000000000000000;
    //Массив, хранящий лимиты бонусов
    uint[] public bonusesLimits;

    /**
    * @dev инициализация контракта рассчёта бонусов
    */
    function SaleBonuses() public {
        //Инициализируем границы бонусов
        bonusesLimits.length = 5;
        //Нулевое значение нужно для упрощения функции рассчёта
        bonusesLimits[0] = 0;
        bonusesLimits[1] = 94340000000000000000000;//188679000000000000000000;
        bonusesLimits[2] = 183626000000000000000000;//367250000000000000000000;
        bonusesLimits[3] = 266960000000000000000000;//533916000000000000000000;
        bonusesLimits[4] = 346324000000000000000000;//692646000000000000000000;
    }


    /**
    * @dev Рассчитываем бонус токенов, получаемых при предпродаже токенов
    * @param amount - сумма платежа пользователя. Нужна, чтобы можно было посчитать
    * точное количество возвращаемых токенов, в пограничных случах
    * @param count - текущее общее количество токенов
    * @param rate - сколько токенов мы получим за 1 Ether.
    * @return количество токенов, которые получит покупатель, за данный платёж, с учётом бонусов Pre-Ico, и сумма возврата,
    * назначаемая, в случае, если покупатель превысил HardCapPreIco.
    */
    function calculateSaleBonusWithPreSale(uint amount, uint count, uint rate) private  constant returns (uint256 purchasedTokens, uint256 returnAmount) {
        //Получаем новый курс, с 50 процентной скидкой (за 1 токен платим в 2 раза меньше)
        uint rateWithBonus = rate.div(2);
        //Получаем количество токенов, с учётом бонуса, и сумму возврата, в случае пресечения капа.
        var (a, b) = calculateCapBonus(amount, count, rateWithBonus, hardcapPreIco);
        //Лишние переменные нужны только из-за того, что напрямую вернять результат не получится.
        purchasedTokens = a;
        returnAmount = b;
    }

    /**
    * @dev Рассчитываем количество токенов, получаемых пользователем, и проверяем их на пересечение капа
    * @param amount - сумма платежа пользователя. Нужна, чтобы можно было посчитать
    * точное количество возвращаемых токенов, в пограничных случах
    * @param count - текущее общее количество токенов
    * @param rate - сколько токенов мы получим за 1 Ether.
    * @param _hardCap - кап, на пересечение которого нужно проверить сумму покупки
    * @return количество токенов, которые получит покупатель, за данный платёж, с учётом бонусов Pre-Ico, и сумма возврата,
    * назначаемая, в случае, если покупатель превысил HardCapPreIco.
    */
    function calculateCapBonus(uint amount, uint count, uint rate, uint _hardCap) private pure returns (uint purchasedTokens, uint returnAmount) {
        //Получаем количество токенов, которое должен получить покупатель, с учётом скидки
        uint tokens = amount.mul(1 ether).div(rate);
        //Количество токенов, оставшихся, до текущей границы бонуса
        uint left = _hardCap - count;
        //Если сумма на обмен больше остатка, до границы капа 
        if (tokens > left) {
            //Начисляем токенов, на сумму остатка, до капа Pre-Sale.
            purchasedTokens = left;
            //Вычитаем добавленные токены
            tokens -= left;
            //Получаем сумму Ether без бонуса, за токены, которые не вошли в кап.
            returnAmount = tokens.mul(rate).div(1 ether);
        //Если сумма меньше или равна остатку, то добавляем её с бонусом полностью
        } else {  
            //Выставляем токены
            purchasedTokens = tokens;
            //И нулевую сумму возврата 
            returnAmount = 0;
        }
    }

    /**
    * @dev Рассчитываем бонус токенов, получаемых при начале продажи токенов
    * @param amount - сумма платежа пользователя. Нужна, чтобы можно было посчитать
    * точное количество возвращаемых токенов, в пограничных случах
    * @param count - текущее общее количество токенов
    * @param rate - сколько токенов мы получим за 1 Ether.
    * @return количество токенов, которые получит покупатель, за данный платёж, с учётом бонусов Ico, и сумма возврата,
    * назначаемая, в случае, если покупатель превысил HardCap.
    */
    function calculateSaleBonusWithSale(uint amount, uint count, uint rate) internal constant returns (uint purchasedTokens, uint returnAmount) {        
        uint256 _purchasedTokens;
        uint256 _returnAmount;
        //Текущий бонус в процентах
        uint bonus;
        //Бонусная скидка. пересчитанная, для курса
        uint rateBonus;
        //Идентификатор текущей границы в массиве
        uint8 id;       
        //Новый курс, с учётом скидки
        uint rateWithBonus;
        //Ставим изначальный бонус в 20%
        bonus = 20;
        //Ставим идентификатору изначально невозможное значение
        id = 99;        
        //Цикл идёт до тех пор, пока мы не проверим все возможные лимиты
        for (uint8 i = 1; i < 5; i++) {
            //Если текущее количество токенов меньше следующего лимита
            if (count < bonusesLimits[i]) {
                //Запоминаем id лимита, и выходим из цыкла
                id = i;
                break;
            }
            bonus -= 5;
        }

        //Если в цикле id не был установлен, то значит, что текущее общее
        //количество токенов уже вышло за границы бонусов, и дальше считать уже не надо 
        if (id == 99) {       
            //Получаем количество токенов, без бонуса, и сумму возврата, в случае пресечения капа.
            (_purchasedTokens, _returnAmount) = calculateCapBonus(amount, count, rate, hardcap);
            //Лишние переменные нужны только из-за того, что напрямую вернять результат не получится.
            purchasedTokens = _purchasedTokens;
            returnAmount = _returnAmount;
        //В противном случае - считаем бонусы
        } else {                
            //Обнуляем переменную, хранящую количество купленных токенов
            purchasedTokens = 0;

            do {
                //Получаем в процентах новую цену, с учётгом скидки
                rateBonus = 100 - bonus;
                rateWithBonus = rate.mul(rateBonus).div(100);
                //Получаем количество токенов, купленных до капа скидки, и сумму, которая в этот лимит не вошла
                (_purchasedTokens, _returnAmount) = calculateCapBonus(amount, count, rateWithBonus, bonusesLimits[id]);    
                //Увеличиваем id лимита бонуса
                id++;
                //Уменьшаем бонус
                bonus -= 5;
                //Сумму платежа заменяем остатком
                amount = _returnAmount;
                //Увеличиваем количество купленных токенов
                purchasedTokens += _purchasedTokens;
                //Увеличиваем текущее количество созданных токенов
                count += _purchasedTokens;
            //Цикл идёт до тех пор, пока не будет обменяна вся сумма, или не пройдём последний кап бонусов 
            } while ((amount > 0) && (id < 5));

            //Если сумма, после этого цикла ещё есть, то это значит, что мы вышли за границы бонусов.
            //ТАким образом, остаток нам нужно просто приплюсовать, без каких либо добавлений.
            if (amount > 0) {
                //Получаем количество токенов, без бонуса, и сумму возврата, в случае пресечения капа.
                (_purchasedTokens, _returnAmount) = calculateCapBonus(amount, count, rate, hardcap);                
                //Лишние переменные нужны только из-за того, что напрямую вернять результат не получится.
                purchasedTokens += _purchasedTokens;
                returnAmount = _returnAmount;
            }
        }
    }

    /**
    * @dev Рассчитываем бонус токенов, получаемых в самом начале продажи
    * @param amount - сумма платежа пользователя. Нужна, чтобы можно было посчитать
    * точное количество возвращаемых токенов, в пограничных случах
    * @param count - Текущее количество проданных токенов
    * @param rate - Сколько токенов мы получим за 1 Ether.
    * @param preIco - Флаг, показывающий, какая часть распродажи идёт. True - PreIco, False - Ico.
    * @return Количество токенов, которое получит покупатель за свой платёж, с учётом скидок, и сумма возврата, для случаев превышения
    * хардкапа.
    */
    function calculateSaleBonus(uint amount, uint count, uint rate, bool preIco) public constant returns (uint purchasedTokens, uint returnAmount) {     
        uint256 _purchasedTokens;
        uint256 _returnAmount; 
        //Если идёт PreIco, то считаем бонусы, там безбонусных токенов нету.
        if (preIco) {
            //ПОлучаем количество наменяных токенов, с учётом бонуса предпродажи. И сумму возврата, для случая превышения хардкапа.
            (_purchasedTokens, _returnAmount) = calculateSaleBonusWithPreSale(amount, count, rate);
        //Если уже начался ICO, то тут всё сложнее
        } else {
            //Если мы ещё не дошли до суммы, за которой бонусы заканчиваются, то
            if (count < bonusesLimits[4]) {
                //Считаем бонусы, за продажу первых токенов
                (_purchasedTokens, _returnAmount) = calculateSaleBonusWithSale(amount, count, rate); 
            //Если этот лимит преодалён, просто проверяем на кап.
            } else {            
                //Получаем количество токенов, без бонуса, и сумму возврата, в случае пресечения капа.
                (_purchasedTokens, _returnAmount) = calculateCapBonus(amount, count, rate, hardcap);
            }
        }
        //Лишние переменные нужны только из-за того, что напрямую вернять результат не получится.
        purchasedTokens = _purchasedTokens;
        returnAmount = _returnAmount;
    }

    
    /**
    * @dev Позволяет владельцу установить верхний предел чеканки токенов.
    * @param _hardcapPreIco Новый верхний предел
    */
    function setPreIcoHardCap(uint _hardcapPreIco) public onlyOwner {
        hardcapPreIco = _hardcapPreIco;
    }    

    /**
    * @dev Позволяет владельцу установить верхний предел чеканки токенов.
    * @param _hardcap Новый верхний предел
    */
    function setHardCap(uint _hardcap) public onlyOwner {
        hardcap = _hardcap;
    }

    /**
    * @dev Позволяет владельцу установить минимальную набираемую сумму.
    * @param _softCap Новая минимальная сумма сбора
    */
    function setSoftCap(uint _softCap) public onlyOwner {
        softCap = _softCap;
    }

    /**
    * @dev Позволяет владельцу установить новое количество токенов, которое будет роздано
    * в ходе программы вознаграждений
    * @param _bountyCap Новый лимит вознаграждений
    */
    function setBountyCap(uint _bountyCap) public onlyOwner {
        bountyCap = _bountyCap;
    }
}

/**
* @title PreIcoSale
* @dev Контракт, куда запихнута часть распродажи, относящаяся к Pre-Ico
*/
contract PreIcoSale is Ownable, Authorizable, SaleBonuses {    
    //Ивент, вызываемый при закрытии предпродажи токенов.
    event PreIcoSaleClosed();

    //Дата старта предпродажи токенов
    uint public startPreIco = 1498302000; //new Date("Jun 24 2017 11:00:00 GMT").getTime() / 1000
    //Продолжительность всей предпродажи токенов
    uint public durationPreIco = 30;
    //Количество токенов, выпущенных в Pre-Ico
    uint public preIcoCountTokens = 0;

    /**
    * @dev Позволяет владельцу установить новое время запуска токена.
    * @param _startPreIco Новое время запуска.
    */
    function setPreIcoStart(uint _startPreIco) public onlyOwner {
        startPreIco = _startPreIco;
    }

    /**
    * @dev Позволяет владельцу токена изменить длительность периода продажи токенов.
    * @param _durationPreIco Новая длительность.
    */
    function setPreIcoDuration(uint _durationPreIco) public onlyOwner {
        durationPreIco = _durationPreIco;
    }
}

/**
* @title IcoSale
* @dev Контракт, куда запихнута основная часть распродажи
*/
contract IcoSale is Ownable, Authorizable, SaleBonuses {    

    //Ивент, вызываемый при закрытии продажи токенов.
    event MainSaleClosed();
    //Дата старта токена
    uint public start = 1498302000; //new Date("Jun 24 2017 11:00:00 GMT").getTime() / 1000
    //Продолжительность всей продажи токенов
    uint public duration = 30;
    //Количество токенов, розданных по программе баунти
    uint public bountyTokensCount = 0;
    //Количество токенов, выпущенных в Ico
    uint public icoCountTokens = 0;

    /**
    * @dev Позволяет владельцу установить новое время запуска токена.
    * @param _start Новое время запуска.
    */
    function setStart(uint _start) public onlyOwner {
        start = _start;
    }

    /**
    * @dev Позволяет владельцу токена изменить длительность периода продажи токенов.
    * @param _duration Новая длительность.
    */
    function setDuration(uint _duration) public onlyOwner {
        duration = _duration;
    }
}

/**
 * @title MainSale 
 * @dev Основной контракт, для продажи QSC токенов
 * 
 * ABI
 * [{"constant":false,"inputs":[{"name":"_multisigVault","type":"address"}],"name":"setMultisigVault","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"authorizerIndex","type":"uint256"}],"name":"getAuthorizer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"exchangeRate","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"altDeposits","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"},{"name":"tokens","type":"uint256"}],"name":"authorizedCreateTokens","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_exchangeRate","type":"address"}],"name":"setExchangeRate","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_token","type":"address"}],"name":"retrieveTokens","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"totalAltDeposits","type":"uint256"}],"name":"setAltDeposit","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"start","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"}],"name":"createTokens","outputs":[],"payable":true,"type":"function"},{"constant":false,"inputs":[{"name":"_addr","type":"address"}],"name":"addAuthorized","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"multisigVault","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_hardcap","type":"uint256"}],"name":"setHardCap","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_start","type":"uint256"}],"name":"setStart","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"token","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"}],"name":"isAuthorized","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":false,"name":"recipient","type":"address"},{"indexed":false,"name":"ether_amount","type":"uint256"},{"indexed":false,"name":"pay_amount","type":"uint256"},{"indexed":false,"name":"exchangerate","type":"uint256"}],"name":"TokenSold","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"recipient","type":"address"},{"indexed":false,"name":"pay_amount","type":"uint256"}],"name":"AuthorizedCreate","type":"event"},{"anonymous":false,"inputs":[],"name":"MainSaleClosed","type":"event"}]
 */
contract MainSale is Ownable, Authorizable, IcoSale, PreIcoSale {
    //Подключение библиотеки безопасной математики
    using SafeMath for uint;
    //Ивент, вызываемый при продаже токенов
    event TokenSold(address recipient, uint etherAmount, uint payAmount, uint exchangerate);
    //Ивент, вызываемый, при добавлении авторизованного пользователя
    event AuthorizedCreate(address recipient, uint payAmount);
    //Ивент, вызываемый, при завершении ICO, до набора софткапа
    event NoSoftCupClosed();

    //Создаём экземпляр контракта QCS токена
    QSCCoin public token = new QSCCoin();

    //Адрес хранилища Ether, куда поступает весь Ether, с покупки токенов.
    address public multisigVault;

    //Переменная, хранящая курс обмена токенов на Ether
    ExchangeRate public exchangeRate_;

    /**
    * @dev Модификатор, разрешающий авторизированное создание токенов только до того момента, как будит
    * достигнут верхний предел количества токенов плюс баунти.
    */
    modifier isUnderBountyCap() {
        require(bountyTokensCount <= bountyCap);
        _;
    }

    /**
    * @dev Модификатор, разрешающий отправку средств, для обмена, только после 
    * завершения софткапа.
    */
    modifier isMoreSoftCap() { 
        require(icoCountTokens > softCap);
        _;
    }
    /**
    * @dev Модификатор, разрешающий вызов функции только в том случае, если
    * софткап не был набран. 
    */
    modifier ifNotSoftCup() {
        require(icoCountTokens < softCap);
        _;
    }

    /**
    * @dev Модификатор, разрешающий начинать обмен токенов только после того, как
    * была завершена чеканка токенов
    */
    modifier isMintingFinished() {
        //Если флаг чеканки стоит в false
        require(!token.mintingFinished());
        _;
    }


        
    /**
    * @dev Модификатор, разрешающий создание токенов, только после того, как
    * время продажи настанет
    */
    modifier saleIsOn() {
        //Если сейчас сроки PRE-ICO
        if (now > startPreIco && now < startPreIco + durationPreIco * 1 days) {
            //Проверяем на кап
            require(preIcoCountTokens <= hardcapPreIco);
        //Если сейчас сроки ICO
        } else if (now > start && now < start + duration * 1 days) {
            //Проверяем на кап
            require(icoCountTokens <= hardcap);
        //Если мы вне сроков
        } else {
            //Тупо отменяем
            require(false);
        }
        _;
    }

    /**
    * @dev Модификатор, запрещающий вызов функции, до начала обмена
    */
    modifier exchangeIsOn() {
        require(token.exchangeStarted());
        _;
    }


  

    /**
    * @dev Позволяет кому угодно создавать токены, путём внесения Ether.
    * @param recipient Получатель, на счёт которого поступят токены
    */
    function createTokens(address recipient) public saleIsOn payable {
        //Получаем курс обмена токенов на Ether
        uint rate = exchangeRate_.getRate("ETH");
        //Получаем сумму платежа пользователя
        uint amount = msg.value;

        uint256 purchasedTokens = 0;
        uint256 returnAmount = 0;

        //Если идёт pre-ico
        if (now > startPreIco && now < startPreIco + durationPreIco * 1 days) {            
            //Считаем количество токенов с учётом бонуса, и сумму, вышедшую за кап.
            (purchasedTokens, returnAmount) = calculateSaleBonus(amount, preIcoCountTokens, rate, true);        
            preIcoCountTokens += purchasedTokens;
        //Если идёт Ico
        } else if (now > start && now < start + duration * 1 days) {            
            //Считаем количество токенов с учётом бонуса, и сумму, вышедшую за кап.
            (purchasedTokens, returnAmount) = calculateSaleBonus(amount, icoCountTokens, rate, false);        
            icoCountTokens += purchasedTokens;
        } 

        //Если мы перешли лимит
        if (returnAmount > 0) {               
            // Отправляем эфир со счёта контракта обратно покупателю. 
            // В случае ошибки - все транзакции будут отменены.
            msg.sender.transfer(returnAmount);
            //Вычитаем сумму возврата, из суммы платежа пользователя
            amount -= returnAmount;
        }
        //Если есть хоть один купленный токен
        if (purchasedTokens > 0) {
            //Отправляем токены на счёт получателя
            token.mint(recipient, purchasedTokens);  
        }      
        // Отправляем эфир со счёта покупателя в хранилище. 
        // В случае ошибки - все транзакции будут отменены.
        multisigVault.transfer(amount);
        //Вызываем ивент отправки токенов
        TokenSold(recipient, msg.value, purchasedTokens, rate);
    }

    /**
    * @dev Предоставляет авторизированный доступ к созданию токенов. Может быть вызвано 
    * только авторизированным пользователем, бонусы на эти токены не начисляются. Можно
    * создавать токены только в пределах баунти. Используется, для раздачи баунти. 
    * @param recipient Получатель токенов.
    * @param tokens Количество токенов, которое необходимо создать. 
    */
    function authorizedCreateTokens(address recipient, uint tokens) public onlyAuthorized isUnderBountyCap {      
        //Отправляем токены на счёт получателя
        token.mint(recipient, tokens);
        //Добавляем созданные токены, к счётчику созданных баунти токенов
        bountyTokensCount += tokens;
        //Выполняем ивент авторизированного создания
        AuthorizedCreate(recipient, tokens);
    }
    
    /**
    * @dev Позволяет владельцу указать адрес хранилища 'командных' токенов.
    * @param _teamTokens Новый адрес хранилища токенов
    */
    function setTeamTokens(address _teamTokens) public onlyOwner {
        //ТОлько, если переданный адрес не пустой
        if (_teamTokens != address(0)) {
            token.setTeamTokens(_teamTokens);
        }
    }

    /**
    * @dev Позволяет владельцу изменить адрес основного хранилища Ether.
    * @param _multisigVault Новый адрес основного хранилища
    */
    function setMultisigVault(address _multisigVault) public onlyOwner {
        //ТОлько, если переданный адрес не пустой
        if (_multisigVault != address(0)) {
            multisigVault = _multisigVault;
        }
    }

    /**
    * @dev Позволяет владельцу указать контракт, который управляет курсом обмена.
    * @param _exchangeRate Адрес нового владельца контракта курса обмена.
    */
    function setExchangeRate(address _exchangeRate) public onlyOwner {
        exchangeRate_ = ExchangeRate(_exchangeRate);
    }
    
    /**
    * @dev позволяет владельцу контракта запустить торги токенами, 
    * что активирует возможность переводов токенов сосчёта на счёт
    */
    function startTrading() public onlyOwner {
        //Запускаем торги
        token.startTrading();
    }

    /**
    * @dev Позволяет владельцу завершить чеканку токенов. Будут проставлены все ограничивающие
    * флаги, и чеканка будет заверршена. После чего, право собственности на PAY-токен будет 
    * передано этому владельцу.  
    */
    function finishMinting() public onlyOwner {
        // Записываем количество всех выданных токенов
        uint issuedTokenSupply = token.totalSupply();

        //Если ICO было завершено до набора софткапа
        if (icoCountTokens < softCap) {
            // Ставим флаги, запрещающие чеканку новых токенов
            token.finishMinting();
            // Передаём владение контрактом создателю токенов
            token.transferOwnership(owner);
            // Вызываем событие завершения продажи токенов, и начала возврата 
            //из-за недосбора средств.
            NoSoftCupClosed();
        //Если всё ок, бабки собрали
        } else {
            //Адрес хранения командных токенов должен существовать. Иначе - ошибка.
            require(token.teamTokens() != 0);
            //Вычитаем из общего количества токенов те, которые были розданы в ходе 
            //программы вознаграждения.
            issuedTokenSupply -= bountyTokensCount;
            //Рассчитываем количество командных токенов - они составят
            //10 процентов от общей суммы проданных токенов.         
            uint teamTokensCount = issuedTokenSupply.div(9); 
            // Отправляем командные токены, на адрес, не имеющий
            // никаких ограничений.
            token.mint(token.teamTokens(), teamTokensCount);
            //Рассчитываем количество наградных командных токенов -
            // они составят 3 процента от общей суммы проданных токенов.         
            teamTokensCount = issuedTokenSupply.mul(3).div(90); 
            // Отправляем наградные командные токены, на адрес, не имеющий
            // никаких ограничений.
            token.mint(token.teamBountyTokens(), teamTokensCount);

            // Ставим флаги, запрещающие чеканку новых токенов
            token.finishMinting();
            // Передаём владение контрактом создателю токенов
            token.transferOwnership(owner);
            // Вызываем событие завершения продажи токенов.
            MainSaleClosed();
        }
    }

    /**
    * @dev Позволяет владельцу передать ERC20 токены в основное хранилище.
    * @param _token Адрес контракта ERC20
    */
    function retrieveTokens(address _token) public onlyOwner {
        ERC20 tokenErc20 = ERC20(_token);
        tokenErc20.transfer(multisigVault, token.balanceOf(this));
    }

    /**
    * @dev Запасной вариант функции создания токенов, который создаёт токены,
    * на всю отправленную сумму, и записываем их на адрес отправителя сообщения.
    */
    function() external payable {
        createTokens(msg.sender);
    }    

    /**
    * @dev Вносим токены, для операций обмена. Мы можем начать делать это 
    * только в случае набора софткапа, и завершения чеканки токенов.
    */
    function setTokensToRetrieve() public onlyOwner isMoreSoftCap isMintingFinished payable {        
        //Получаем курс обмена Ether на токены
        uint rate = exchangeRate_.getRate("QSC");
        //Вызываем соыбтие обмена
        token.returnTokens(msg.value, rate);
    }

    /**
    * @dev функция возврата Ether, в обмен на коины. По сути - оболочка, 
    * для вызова более глубокой функции. Функция доступна для вызова только
    * после первого внесения средств на обмен.
    */
    function returnEtherFromCoins() public exchangeIsOn {
        //Запрашиваем возврат коинов, от имени отправителя сообщения
        token.getEther(msg.sender);
    }

    
    /**
    * @dev функция возврата Ether, в обмен на коины, в случае, если 
    * софткап не был набран. Может быть вызвана только после завершения 
    * продажи токенов.
    */
    function returnEtherFromNoSoftCup() public isMintingFinished ifNotSoftCup {
        //Получаем курс обмена токенов на Ether
        uint rate = exchangeRate_.getRate("ETH");
        //Запрашиваем возврат коинов, от имени отправителя сообщения
        token.returnEther(msg.sender, rate);
    }

    /**
    * @dev Функция принимает токены на данный счёт, для возврата средств, 
    * в случае ненабора софткапа. 
    */
    function getEtherToReturn() public payable {
        //тут даже вызывать ничего не надо. Просто бабки прийдут на счёт 
        //контракта, и будут возвращаться пользователям в обмен на токены. 
    }
    
    /**
    * @dev Позволяет узнать баланс юзера.
    * @param _token Адрес контракта 
    */
    function getBalance(address _token) public constant returns(uint) {
        return token.balanceOf(_token);
    }
}

/**
* @dev Контракт, реализующий специфически защищённый кошелёк, для хранения
* собранных средств.
*/
contract MultiSig is Ownable {
    /**
    * @dev Структура, описывающая подтверждение транзакции
    */
    struct MultiTransaction {
        //Подтверждение транзакции от первого подписывателя
        address firstSigner;
        //Подтверждение транзакции от второго подписывателя
        address secondSigner;
        //Статус транзакции
        uint8 status;
        //Сумма перевода в wei
        uint cost;
        //Целевой адрес перевода
        address to;
    }

    //Текущее количество созданных транзакций
    uint private transactionsCount = 0;
    //Первый адрес подписки
    address private firstSigner;
    //Второй адрес подписки
    address private secondSigner;
    //Список транзакций кошелька
    mapping(bytes32 => MultiTransaction) transactions;

    /**
    * @dev модификатор, разрешающий выполнения функции только в том случае, если
    * оба адреса подписывания были установлены
    */
    modifier isSignersContains {        
        require((firstSigner != address(0)) && (secondSigner != address(0)));
        _;
    }

    /**
    * @dev модификатор, разрешающий выполнения функции только в том случае, если
    * функцию вызывает один из подписывателей.
    */
    modifier ifSigner(address sender) {        
        require((firstSigner == sender) || (secondSigner == sender));
        _;
    }

    /**
    * @dev просто функцию, по приёму средств добавил. Она нифига не делает, и я 
    * не уверен, что она вообще нужна, но пусть будет.
    */
    function() external payable {}    

    /**
    * @dev Позволяет узнать баланс кошелька.
    */
    function getBalance() public onlyOwner constant returns(uint) {
        return this.balance;
    }

    /**
    * @dev Устанавливаем адрес первого подписывателя платежа
    */
    function addFirstSigner(address _firstSigner) public onlyOwner {
        //Если адрес вообще есть
        require(_firstSigner != address(0));
        //Устанавливаем
        firstSigner = _firstSigner;
    }

    /**
    * @dev Устанавливаем адрес второго подписывателя платежа
    */
    function addSecondSigner(address _secondSigner) public onlyOwner {
        //Если адрес вообще есть
        require(_secondSigner != address(0));
        //Устанавливаем
        secondSigner = _secondSigner;
    }

    /**
    * @dev Создаём новую транзакцию. Вызвать может только владелец контракта, после добавления двух подписывателей.
    * @param _to конечный адрес перевода
    * @param _cost сумма перевода
    * @return хеш-номер транзакции
    */
    function setTransaction(address _to, uint _cost) public onlyOwner isSignersContains constant returns(bytes32) {
        //Если на счету у нас сумма меньше, чем требуется перевести, то будет выдана ошибка
        //Если сумма перевода пустая - будет выведена ошибка
        require((this.balance >= _cost) && (_cost > 0));
        //Если конечный адрес перевода - пустой, то будет выведена ошибка
        require(_to != address(0));
        //Создаём хеш-подпись транзакции
        bytes32 transactionHash = keccak256(transactionsCount, _cost, _to, owner);
        //Заполняем поля транзакции
        //Указываем получателя
        transactions[transactionHash].to = _to;
        //Указываем сумму перевода
        transactions[transactionHash].cost = _cost;
        //Указываем текущий статус
        transactions[transactionHash].status = 1;
        //Возвращаем хеш-подпись данной транзакции
        return transactionHash;
    }

    /**
    * @dev Позволяет выполнить подписывание транзакции. Может быть выполнена только одним из подписывателей,
    * и только в том случае, если они оба были назначены.
    * @param transactionHash - хеш-номер транзакции
    */
    function signTransaction(bytes32 transactionHash) public isSignersContains ifSigner(msg.sender) {
        //Если такой транзакции не существует - будет выдана ошибка
        //Если транзакция уже проведена - будет выведена ошибка
        require((transactions[transactionHash].status > 0) && (transactions[transactionHash].status < 3));
        //Если на счету у нас сумма меньше, чем требуется перевести, то будет выдана ошибка
        require(this.balance >= transactions[transactionHash].cost);
        //Если подписывает первый подписыватель
        if (msg.sender == firstSigner) {
            //Если второй ещё не подписал
            if (transactions[transactionHash].secondSigner == address(0)) {
                //Подписываем от имени первого подписывателя
                transactions[transactionHash].firstSigner = msg.sender;
                //Увеличиваем значение статуса
                transactions[transactionHash].status++;
            //Если уже есть подпись второго
            } else {
                //если второй подписыватель действительно тот, за кого себя выдаёт, и у транзакции верный статус
                if ((transactions[transactionHash].secondSigner == secondSigner) && (transactions[transactionHash].status == 2)) {
                    //Увеличиваем значение статуса
                    transactions[transactionHash].status++;
                    //Проставляем вторую подпись
                    transactions[transactionHash].firstSigner = msg.sender;
                    //Отправляем бабки
                    transactions[transactionHash].to.transfer(transactions[transactionHash].cost);
                }
            }
        //Если подписывает второй подписыватель
        } else if (msg.sender == secondSigner) {
            //Если первый ещё не подписал
            if (transactions[transactionHash].firstSigner == address(0)) {
                //Подписываем от имени второго подписывателя
                transactions[transactionHash].secondSigner = msg.sender;
                //Увеличиваем значение статуса
                transactions[transactionHash].status++;
            //Если уже есть подпись первого
            } else {
                //если первый подписыватель действительно тот, за кого себя выдаёт, и у транзакции верный статус
                if ((transactions[transactionHash].firstSigner == firstSigner) && (transactions[transactionHash].status == 2)) {
                    //Увеличиваем значение статуса
                    transactions[transactionHash].status++;
                    //Проставляем вторую подпись
                    transactions[transactionHash].secondSigner = msg.sender;
                    //Отправляем бабки
                    transactions[transactionHash].to.transfer(transactions[transactionHash].cost);
                }
            }
        }
    }
}