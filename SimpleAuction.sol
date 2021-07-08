pragma solidity >=0.4.22 <0.7.0;

contract SimpleAuction {

    // 受益者
    address payable public beneficiary;
    // 終了までの秒数
    uint public auctionEndTime;

    // オークションの現在の状態
    address public highestBidder;
    uint public highestBid;

    // 過去の入札金額を引き出す
    mapping(address => uint) pendingReturns;

    // オークションが終了したらtrueをセットする
    // 最初はfalseに初期化されている
    bool ended;

    // オークションの進行状況をDappsが把握するためのイベント
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // 以下は所謂ナットスペックと呼ばれ、
    // スラッシュ３つで認識される。
    // これは、ユーザがトランザクションの確認を求められた時に表示される。

    /// `_biddingTime`秒で受益者のアドレス`_beneficiary`に利益が発生する
    constructor(
        uint _biddingTime,
        address payable _beneficiary
    ) public {
        beneficiary = _beneficiary;
        // nowで現在時刻のunixタイムスタンプが取得できる
        auctionEndTime = now + _biddingTime;
    }

    /// このトランザクションで送金された金額を使用して、入札をする。
    /// この金額はオークションで落札できなかった時だけ返金される。
    function bid() public payable {
        // 引数は必要ない。全ての情報はトランザクションの一部である。
        // payableのキーワードはファンクションがetherを受け取ることができるようにするために必要である。

        // 入札期間が終了している場合はリバートする。
        require(
            now <= auctionEndTime,
            "Auction already ended."
        );

        // 入札金額が現在価格以下だった場合は返金する。
        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        if (highestBid != 0) {
            // シンプルに `highestBidder.send(highestBid)`で返金するのはセキュリティーリスクがある。
            // なぜなら、信頼できないコントラクトが実行している可能性がある。
            // 受取人自身に引き出してもらうのが常により安全である。
            // （そのためここで送金処理は行わない）
            pendingReturns[highestBidder] += highestBid;
        }
        // 最高額入札者と入札額を更新
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// 高値が更新された入札の引き出しを行う
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {

            // `send`が終了する前に、レシービングコールからこの関数を再度実行できるので、
            // 先にここを0にしておくことは重要である。
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // 単に残高をリセットするだけなので、ここでthrowする必要はない。
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// オークション終了時に、最高金額の入札額を受益者に送信する。
    function auctionEnd() public {
        // 外部のコントラクトと相互作用を持つ（可能性がある）関数の構築する場合は下記のガイドラインに従う
        // 1. 条件を確認する
        // 2. アクションを実行して、状態を変更する。
        // 3. 他のコントラクトとインタラクションする
        // これらの段階が混ざってしまうと、他のコントラクトが正しいコントラクトをコールバックできてしまい、
        // 状態を変更したり、アクション(etherの払い出し)を複数回実行できる。
        // もし関数が内部呼び出しを通じて間接的にでも外部のコントラクトとの相互作用を持つ可能性があるのであれば、
        // 外部のコントラクトとの相互作用を考慮する必要がある。

        // 1. 条件
        // オークションの入札期間が終了していること
        require(now >= auctionEndTime, "Auction not yet ended.");
        // オークションがすでに終了していないこと
        require(!ended, "auctionEnd has already been called.");

        // 2. 効果
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. 相互作用
        beneficiary.transfer(highestBid);
    }
}
