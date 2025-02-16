/**
 Indicates Asset connection status (i.e. if courier is publishing his location)
 */
@objc
public enum ConnectionState: Int {
    /**
     Asset is connected to tracking system and we're receiving his position
     */
    case online

    /**
     Asset is not connected
     */
    case offline
    
    /**
     Connection has failed
     */
    case failed
}
