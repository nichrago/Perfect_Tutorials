

import PerfectLib
import MySQL


let HOST = "localhost"
let USER = "perfectuser"
let PASSWORD = "perfectpass"
let DB_NAME = "PerfectTesting"
let TABLE_NAME = "Messages"


func createDatabase() {
    let mysql = MySQL()
    let connected = mysql.connect(HOST, user: USER, password: PASSWORD)
    
    guard connected else { print(mysql.errorMessage()); return }
    
    defer { mysql.close() }
    
    var isDatabase = mysql.selectDatabase(DB_NAME)
    if !isDatabase {
        isDatabase = mysql.query("CREATE DATABASE \(DB_NAME);")
    }
    
    let isTable = mysql.query("CREATE TABLE IF NOT EXISTS \(TABLE_NAME) (message TEXT, author TEXT);")
    
    guard isDatabase && isTable else {
        print(mysql.errorMessage()); return
    }
}


public func PerfectServerModuleInit() {
    Routing.Handler.registerGlobally()
    
    Routing.Routes["GET", "/messages"] = { _ in return GetAllMessages() }
    Routing.Routes["GET", "/messagesForAuthor"] = { _ in return GetMessagesForAuthor() }
    Routing.Routes["POST", "/postMessage"] = { _ in return PostMessage() }
    
    createDatabase()
}


func resultsToJSON(results results: MySQL.Results, _ fields: [String]) -> String? {
    if results.numFields() != fields.count { return nil }
    
    let encoder = JSONEncoder()
    var rowValues = [[String: JSONValue]]()
    
    results.forEachRow{ row in
        var rowValue = [String: JSONValue]()
        for c in 0 ..< fields.count {
            rowValue[fields[c]] = row[c]
        }
        rowValues.append(rowValue)
    }
    
    var responseString = "["
    
    do {
        for c in 0 ..< rowValues.count {
            let rowJSON = try encoder.encode(rowValues[c])
            responseString += rowJSON
            if c != rowValues.count - 1 { responseString += "," }
            else { responseString += "]" }
        }
        return responseString
    } catch {
        return nil
    }
}


class GetAllMessages: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        let mysql = MySQL()
        let connected = mysql.connect(HOST, user: USER, password: PASSWORD)
        
        guard connected else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Couldn't connect to MySQL")
            response.requestCompletedCallback(); return
        }
        
        mysql.selectDatabase(DB_NAME)
        defer { mysql.close() }
        
        let querySuccess = mysql.query("SELECT * FROM \(TABLE_NAME);")
        guard querySuccess else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Things went wrong querying the table")
            response.requestCompletedCallback(); return
        }
        
        let results = mysql.storeResults()
        guard results != nil else {
            print("no messages were found")
            response.setStatus(500, message: "No Data in the table")
            response.requestCompletedCallback(); return
        }
        
        let result = resultsToJSON(results: results!, ["message", "author"])
        guard result != nil else {
            print("json encoding did not work very well... or at all")
            response.setStatus(500, message: "no goo json encoding oops")
            response.requestCompletedCallback(); return
        }
        
        response.appendBodyString(result!)
        response.setStatus(200, message: "Mission Success Here is all the messages")
        response.requestCompletedCallback()
    }
}


class GetMessagesForAuthor: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        let mysql = MySQL()
        let connected = mysql.connect(HOST, user: USER, password: PASSWORD)
        
        guard connected else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "couldnt connect to mysql")
            response.requestCompletedCallback(); return
        }
        
        let author = request.param("author")
        guard author != nil else {
            response.setStatus(400, message: "give me an author dammit")
            response.requestCompletedCallback(); return
        }
        
        mysql.selectDatabase(DB_NAME)
        defer { mysql.close() }
        
        let querySuccess = mysql.query("SELECT * FROM \(TABLE_NAME) WHERE author='\(author!)';")
        guard querySuccess else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Query Error whatevs")
            response.requestCompletedCallback(); return
        }
        
        let results = mysql.storeResults()
        guard results != nil else {
            response.setStatus(500, message: "no results sorry mate")
            response.requestCompletedCallback(); return
        }
        
        let result = resultsToJSON(results: results!, ["message", "author"])
        guard result != nil else {
            response.setStatus(500, message: "json encoding fail")
            response.requestCompletedCallback(); return
        }
        
        response.appendBodyString(result!)
        response.setStatus(200, message: "Mission Success whatsgud")
        response.requestCompletedCallback()
    }
}


class PostMessage: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        let params = request.postParams
        guard params.count == 2 else {
            response.setStatus(400, message: "Params were no good")
            response.requestCompletedCallback(); return
        }
        
        let message = params[0].1
        let author = params[1].1
        
        let mysql = MySQL()
        let connected = mysql.connect(HOST, user: USER, password: PASSWORD)
        
        guard connected else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Didnt connect to the thing bro")
            response.requestCompletedCallback(); return
        }
        
        mysql.selectDatabase(DB_NAME)
        let querySuccess = mysql.query("INSERT INTO \(TABLE_NAME) VALUES ('\(message)', '\(author)');")
        guard querySuccess else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "couldnt because it got mad")
            response.requestCompletedCallback(); return
        }
        
        response.setStatus(200, message: "post success thank you postman sorry for saying bro")
        response.requestCompletedCallback()
    }
}




















