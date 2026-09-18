// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Decentradonate
/// @notice Kontrak sederhana untuk donasi mikro transparan.
/// @dev SENGAJA DIBUAT SESEDERHANA MUNGKIN untuk scope tugas 12 minggu.
///      Setiap donasi LANGSUNG diteruskan ke organizer (bukan ditahan di
///      kontrak), supaya kita tidak perlu fungsi "withdraw" terpisah dan
///      tidak ada risiko dana "terjebak" di kontrak. Event yang di-emit
///      adalah yang membuat riwayat transaksi TRANSPARAN dan bisa dilacak
///      siapa pun di block explorer (mis. PolygonScan Amoy).
contract Decentradonate {
    struct Campaign {
        address organizer;
        string title;
        uint256 targetAmount;   // dalam wei (1 MATIC = 1e18 wei)
        uint256 collectedAmount;
        bool active;
    }

    Campaign[] public campaigns;

    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed organizer,
        string title,
        uint256 targetAmount
    );

    event DonationReceived(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount
    );

    /// @notice Membuat kampanye baru. Siapa pun bisa membuat kampanye
    ///         (tidak ada whitelist admin) — cocok untuk model "open platform"
    ///         seperti disebut di PRD (mirip GoFundMe/KitaBisa).
    function createCampaign(string calldata title, uint256 targetAmount)
        external
        returns (uint256 campaignId)
    {
        require(bytes(title).length > 0, "Judul tidak boleh kosong");
        require(targetAmount > 0, "Target harus lebih dari 0");

        campaigns.push(Campaign({
            organizer: msg.sender,
            title: title,
            targetAmount: targetAmount,
            collectedAmount: 0,
            active: true
        }));

        campaignId = campaigns.length - 1;
        emit CampaignCreated(campaignId, msg.sender, title, targetAmount);
    }

    /// @notice Fungsi donasi utama — INI yang akan dipanggil dari
    ///         `donation_repository_impl.dart` di Langkah 2.3 lewat
    ///         `web3dart`. `payable` berarti fungsi ini BISA menerima
    ///         native token (MATIC) yang dikirim bersamaan pemanggilan.
    function donate(uint256 campaignId) external payable {
        require(campaignId < campaigns.length, "Campaign tidak ditemukan");
        require(campaigns[campaignId].active, "Campaign tidak aktif");
        require(msg.value > 0, "Donasi harus lebih dari 0");

        campaigns[campaignId].collectedAmount += msg.value;

        // Transfer langsung ke organizer. `payable(...).transfer(...)`
        // otomatis revert seluruh transaksi kalau transfer gagal — jadi
        // `collectedAmount` di atas juga ikut ter-revert (atomic).
        payable(campaigns[campaignId].organizer).transfer(msg.value);

        emit DonationReceived(campaignId, msg.sender, msg.value);
    }

    function getCampaignCount() external view returns (uint256) {
        return campaigns.length;
    }

    function getCampaign(uint256 campaignId)
        external
        view
        returns (
            address organizer,
            string memory title,
            uint256 targetAmount,
            uint256 collectedAmount,
            bool active
        )
    {
        require(campaignId < campaigns.length, "Campaign tidak ditemukan");
        Campaign memory c = campaigns[campaignId];
        return (c.organizer, c.title, c.targetAmount, c.collectedAmount, c.active);
    }
}
