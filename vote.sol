pragma solidity >=0.4.22 <0.7.0;

/// @title 候補者名簿単位でコントラクトを作成する
contract Ballot {

    // 投票者の構造体
    struct Voter {
        uint weight; // 一票の重み。基本は1だが、委任を受けている場合は増加していく。
        bool voted;  // 投票が完了しているか
        address delegate; // 投票を委任しているか
        uint vote;   // 何番の提案に投票したか
    }

    // 投票を受ける提案の構造体
    struct Proposal {
        bytes32 name;   // 提案名
        uint voteCount; // 得票数。Voterのweightが加算されていく
    }

    // この投票の管理者
    address public chairperson;

    // 投票の権利が与えられたアドレスに対して、投票状況をマップで管理する
    mapping(address => Voter) public voters;

    // 提案一覧を配列で管理する
    Proposal[] public proposals;

    // 候補者名簿コントラクトを新規作成する
    // 引数はbytes32[]なので、Remixを仕様する際は、
    // ["0x01","0x02","0x03"]の様に引数を書く
    constructor(bytes32[] memory proposalNames) public {
        chairperson = msg.sender;
        // 管理者に投票権を追加する
        // 一票の価値は1が基本
        voters[chairperson].weight = 1;

        // それぞれの提案を初期化して、proposals配列に追加する
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // アドレスに対して投票権を付与する
    // この関数は管理者のみ実行できる
    function giveRightToVote(address voter) public {
        // 実行者が管理者か確認する
        // requireが失敗した場合は、リバートされて前の状態に戻る
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        // 投票済みの場合は無効
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        // weightは1以上でないと投票できない
        require(voters[voter].weight == 0);
        // 一票の価値を1に設定
        voters[voter].weight = 1;
    }

    // 投票権を委任する
    function delegate(address to) public {
        // 実行者の投票状況の参照を取得する
        Voter storage sender = voters[msg.sender];
        // すでに投票済みの場合は無効
        require(!sender.voted, "You already voted.");

        // 委任先が自分自身の場合は無効
        require(to != msg.sender, "Self-delegation is disallowed.");

        // toで指定された人がさらに委任している場合は、さらにデリゲーションを繰り返して行く。
        // 一般的にこういうループは、非常に長い処理になって多くのgasを消費する可能性があるため危険である。
        // 今回は委任を実行しないが、そうでないと長いループがコントラクトを完全にスタックさせてしまうかもしれない。
        // address(0)は'0x0000000000000000000000000000000000000000'が返る。
        // これは初期化されていないaddressの値
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // 無限ループ対策で、自分自身への委任が発生した場合は無効
            require(to != msg.sender, "Found loop in delegation.");
        }

        // senderには参照を受け取っているので `voters[msg.sender].voted`によって、voters中身が変更される
        sender.voted = true;
        sender.delegate = to;

        // 委任先の投票状況の参照を取得する
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // もし委任先がすでに投票済みであれば、
            // 直接投票先にweightを加算する
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // 委任先がまだ投票していない場合は
            // 委任先の一票の重みに加算する
            delegate_.weight += sender.weight;
        }
    }

    // 投票する（委任された票を含めて）
    // proposalには配列のインデックスを受け取る
    function vote(uint proposal) public {
        // 実行者の投票状況を取得する
        Voter storage sender = voters[msg.sender];

        // weightが0であれば、投票権がないので無効
        require(sender.weight != 0, "Has no right to vote");
        // votedがfalseでなければ、投票済みなので無効
        require(!sender.voted, "Already voted.");

        sender.voted = true;
        sender.vote = proposal;

        // もしproposalが配列の範囲外の場合は、
        // コントラクトが失敗し、全ての変更がリバートされる
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev 勝った提案を取得する
    function winningProposal() public view returns (uint winningProposal_)
    {
        // 勝者の得票数
        uint winningVoteCount = 0;

        // 提案全てを確認する
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                // この値がリターンされる
                winningProposal_ = p;
            }
        }
    }

    // 勝った提案の名前を返却する
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}
