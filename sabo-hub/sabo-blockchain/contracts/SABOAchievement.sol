// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SABOAchievement
 * @notice Non-transferable (Soulbound) NFT achievements for the SABO ecosystem.
 *
 * Each achievement type has a unique typeId, rarity tier, and metadata URI.
 * Only authorized minters (backend services) can mint achievements to users.
 * Achievements are soulbound — they cannot be transferred between addresses.
 *
 * Rarity tiers: 0=Common, 1=Rare, 2=Epic, 3=Legendary, 4=Mythic
 */
contract SABOAchievement is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    // ─── Types ──────────────────────────────────────────

    enum Rarity { Common, Rare, Epic, Legendary, Mythic }

    struct AchievementType {
        string name;        // e.g. "Founder", "Speed Demon", "Sắt Đá"
        Rarity rarity;
        string metadataURI; // IPFS or URL for the NFT metadata/image
        uint256 maxSupply;  // 0 = unlimited
        uint256 minted;
        bool active;
    }

    struct Achievement {
        uint256 typeId;
        uint256 mintedAt;
        address originalOwner; // soulbound — tracks first recipient
    }

    // ─── State ──────────────────────────────────────────

    /// Auto-increment token ID
    uint256 private _nextTokenId;

    /// Achievement type registry
    uint256 public achievementTypeCount;
    mapping(uint256 => AchievementType) public achievementTypes;

    /// Token ID → achievement data
    mapping(uint256 => Achievement) public achievements;

    /// Tracks which addresses have which types (address → typeId → has)
    mapping(address => mapping(uint256 => bool)) public hasAchievement;

    /// Authorized minters (backend services)
    mapping(address => bool) public minters;

    // ─── Events ─────────────────────────────────────────

    event AchievementTypeCreated(uint256 indexed typeId, string name, Rarity rarity, uint256 maxSupply);
    event AchievementTypeUpdated(uint256 indexed typeId, bool active);
    event AchievementMinted(address indexed to, uint256 indexed tokenId, uint256 indexed typeId, Rarity rarity);
    event MinterUpdated(address indexed minter, bool authorized);

    // ─── Modifiers ──────────────────────────────────────

    modifier onlyMinter() {
        require(minters[msg.sender] || msg.sender == owner(), "SABO-NFT: not a minter");
        _;
    }

    // ─── Constructor ────────────────────────────────────

    constructor() ERC721("SABO Achievement", "SABOACH") Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    // ─── Admin: Achievement Types ───────────────────────

    /**
     * @notice Create a new achievement type.
     * @param name Human-readable name
     * @param rarity Rarity tier (0-4)
     * @param metadataURI IPFS/HTTP URI for the NFT metadata
     * @param maxSupply Maximum mintable (0 = unlimited)
     */
    function createAchievementType(
        string calldata name,
        Rarity rarity,
        string calldata metadataURI,
        uint256 maxSupply
    ) external onlyOwner returns (uint256 typeId) {
        typeId = achievementTypeCount;
        achievementTypes[typeId] = AchievementType({
            name: name,
            rarity: rarity,
            metadataURI: metadataURI,
            maxSupply: maxSupply,
            minted: 0,
            active: true
        });
        achievementTypeCount++;
        emit AchievementTypeCreated(typeId, name, rarity, maxSupply);
    }

    /**
     * @notice Toggle an achievement type active/inactive.
     */
    function setAchievementTypeActive(uint256 typeId, bool active) external onlyOwner {
        require(typeId < achievementTypeCount, "SABO-NFT: type does not exist");
        achievementTypes[typeId].active = active;
        emit AchievementTypeUpdated(typeId, active);
    }

    /**
     * @notice Update metadata URI for an achievement type.
     */
    function setAchievementTypeURI(uint256 typeId, string calldata metadataURI) external onlyOwner {
        require(typeId < achievementTypeCount, "SABO-NFT: type does not exist");
        achievementTypes[typeId].metadataURI = metadataURI;
    }

    // ─── Minter Management ──────────────────────────────

    function setMinter(address minter, bool authorized) external onlyOwner {
        minters[minter] = authorized;
        emit MinterUpdated(minter, authorized);
    }

    // ─── Minting ────────────────────────────────────────

    /**
     * @notice Mint an achievement NFT to a user.
     * @dev Each address can only hold one of each achievement type (soulbound uniqueness).
     * @param to Recipient address
     * @param typeId Achievement type to mint
     */
    function mint(address to, uint256 typeId) external onlyMinter returns (uint256 tokenId) {
        require(typeId < achievementTypeCount, "SABO-NFT: type does not exist");
        AchievementType storage aType = achievementTypes[typeId];
        require(aType.active, "SABO-NFT: type is not active");
        require(!hasAchievement[to][typeId], "SABO-NFT: already has this achievement");
        require(aType.maxSupply == 0 || aType.minted < aType.maxSupply, "SABO-NFT: max supply reached");

        tokenId = _nextTokenId++;
        aType.minted++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, aType.metadataURI);

        achievements[tokenId] = Achievement({
            typeId: typeId,
            mintedAt: block.timestamp,
            originalOwner: to
        });
        hasAchievement[to][typeId] = true;

        emit AchievementMinted(to, tokenId, typeId, aType.rarity);
    }

    /**
     * @notice Batch mint multiple achievement types to a user.
     */
    function mintBatch(address to, uint256[] calldata typeIds) external onlyMinter {
        for (uint256 i = 0; i < typeIds.length; i++) {
            uint256 typeId = typeIds[i];
            if (typeId < achievementTypeCount &&
                achievementTypes[typeId].active &&
                !hasAchievement[to][typeId] &&
                (achievementTypes[typeId].maxSupply == 0 || achievementTypes[typeId].minted < achievementTypes[typeId].maxSupply))
            {
                uint256 tokenId = _nextTokenId++;
                achievementTypes[typeId].minted++;

                _safeMint(to, tokenId);
                _setTokenURI(tokenId, achievementTypes[typeId].metadataURI);

                achievements[tokenId] = Achievement({
                    typeId: typeId,
                    mintedAt: block.timestamp,
                    originalOwner: to
                });
                hasAchievement[to][typeId] = true;

                emit AchievementMinted(to, tokenId, typeId, achievementTypes[typeId].rarity);
            }
        }
    }

    // ─── Soulbound Logic ────────────────────────────────
    // Override transfer functions to prevent transfers (soulbound)

    function transferFrom(address, address, uint256) public pure override(ERC721, IERC721) {
        revert("SABO-NFT: soulbound, cannot transfer");
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public pure override(ERC721, IERC721) {
        revert("SABO-NFT: soulbound, cannot transfer");
    }

    // ─── View Functions ─────────────────────────────────

    /**
     * @notice Get all achievement token IDs for an address.
     */
    function getAchievements(address owner) external view returns (uint256[] memory) {
        uint256 count = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    /**
     * @notice Get achievement details for a token ID.
     */
    function getAchievementDetail(uint256 tokenId) external view returns (
        uint256 typeId,
        string memory name,
        Rarity rarity,
        uint256 mintedAt,
        address originalOwner,
        string memory uri
    ) {
        Achievement memory a = achievements[tokenId];
        AchievementType memory aType = achievementTypes[a.typeId];
        return (
            a.typeId,
            aType.name,
            aType.rarity,
            a.mintedAt,
            a.originalOwner,
            tokenURI(tokenId)
        );
    }

    /**
     * @notice Get all active achievement types.
     */
    function getActiveTypes() external view returns (uint256[] memory ids, string[] memory names, uint8[] memory rarities) {
        // Count active
        uint256 active = 0;
        for (uint256 i = 0; i < achievementTypeCount; i++) {
            if (achievementTypes[i].active) active++;
        }

        ids = new uint256[](active);
        names = new string[](active);
        rarities = new uint8[](active);

        uint256 j = 0;
        for (uint256 i = 0; i < achievementTypeCount; i++) {
            if (achievementTypes[i].active) {
                ids[j] = i;
                names[j] = achievementTypes[i].name;
                rarities[j] = uint8(achievementTypes[i].rarity);
                j++;
            }
        }
    }

    /**
     * @notice Get achievement count by rarity for an address.
     */
    function getAchievementCountByRarity(address owner) external view returns (
        uint256 common,
        uint256 rare,
        uint256 epic,
        uint256 legendary,
        uint256 mythic
    ) {
        uint256 count = balanceOf(owner);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            Rarity r = achievementTypes[achievements[tokenId].typeId].rarity;
            if (r == Rarity.Common) common++;
            else if (r == Rarity.Rare) rare++;
            else if (r == Rarity.Epic) epic++;
            else if (r == Rarity.Legendary) legendary++;
            else if (r == Rarity.Mythic) mythic++;
        }
    }

    // ─── Required Overrides ─────────────────────────────

    function _update(address to, uint256 tokenId, address auth)
        internal override(ERC721, ERC721Enumerable) returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
