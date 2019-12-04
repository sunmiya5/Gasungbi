//
//  SearchTableViewController.swift
//  Gasungbi
//
//  Created by 강선미 on 27/11/2019.
//  Copyright © 2019 Sunmi Kang. All rights reserved.
//

import UIKit
import CoreData

class SearchTableViewController: UIViewController, NSFetchedResultsControllerDelegate {

    // MARK: - Properties
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var totalCount: Int = 0
    var pageCount: Int = 1
    var keyword: String = ""
    var cellData = [SearchResults]()
   // var fetchedSearchKeyword: NSFetchedResultsController<SearchItem>!
    var favorites: Favorites!
    var recentKeyword: Keyword!
    var searchItem: SearchItem!
   // var fetchedFavorites: NSFetchedResultsController<FavoriteItem>!
//    var favoriteArray = [FavoriteItem]()

    // MARK: - Methods

    fileprivate func setFetchedResultController() {
//        fetchedSearchKeyword = SearchKeywordCoreData.shared.getFetchedResultsController(fromContext: DataController.shared.viewContext)
//        fetchedSearchKeyword.delegate = self
        
//
//        do {
//            try fetchedSearchKeyword.performFetch()
//        } catch {
//            fatalError("The fetch could not be performed: \(error.localizedDescription)")
//        }
        
//        fetchedFavorites = FavoriteItemCoreData.shared.getFetchedResultsController(fromContext: DataController.shared.viewContext)
//        fetchedFavorites.delegate = self
//
//
//        do {
//            try fetchedFavorites.performFetch()
//        } catch {
//            fatalError("The fetch could not be performed: \(error.localizedDescription)")
//        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerTableViewCell()
        self.searchBar.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        navigationItem.hidesSearchBarWhenScrolling = true
       // setFetchedResultController()
       // deleteData()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.hidesSearchBarWhenScrolling = false
    
    }
    
    override func viewDidDisappear(_ animated: Bool) {
         super.viewDidDisappear(animated)
       //  fetchedSearchKeyword = nil
         //fetchedFavorites = nil
     }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
//            let detailVC = segue.destination as! FavoriteListTableViewController
//            detailVC.movie = movies[selectedIndex]
        }
    }
    
    // register TableViewCell
    func registerTableViewCell() {
        self.tableView.register(UINib(nibName: "EmptyTableViewCell", bundle: nil), forCellReuseIdentifier: "EmptyTableViewCell")
        self.tableView.register(UINib(nibName: "SearchTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchTableViewCell")
    }


    // MARK: - Navigation
    func configureTable(data: [SearchResults]) {
        APIManager.search(item: self.keyword) { searchResult in
            if let count = searchResult.value?.total { self.totalCount = Int(count)! }
            if let results = searchResult.value?.items {
                self.cellData = data.isEmpty ? [SearchResults]() : self.cellData
                
                for result in results {
                    self.cellData.append(result)
                }
                self.tableView.reloadData()
            }
            else {
                print("Empty searchResult.value")
            }
        }
    }
    
    var selectedItems: [SearchResults] {
        return cellData.filter { return $0.isSelected }
    }
    
    func deleteData() {
        
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FavoriteItem")

       let result = try? DataController.shared.viewContext.fetch(request)
       let resultData = result as! [NSManagedObject]

       for object in resultData {
           DataController.shared.viewContext.delete(object)
       }

       do {
           try DataController.shared.viewContext.save()
           print("TABLEVIEW-EDIT: saved!")
       } catch let error as NSError  {
           print("Could not save \(error), \(error.userInfo)")
       } catch {
           // add general error handle here
       }

    }
 
    
    func saveCellDataFromSearchKeyword(searchResult: SearchResults) {

        let index: Int = 0
        searchItem = SearchItemCoreData.shared.saveResults(searchResult: searchResult, fromContext: DataController.shared.viewContext, index: index)
        // Save newly created pin.
        do {
            try DataController.shared.save()
        } catch {
            print("Error saving new pin: \(error)")
        }
    }
  
    
    @IBAction func addFavoriteItem(_ sender: Any) {
        favorites = FavoritesCoreData.shared.createFavorites(selectedItems: selectedItems,forSearch: searchItem)
    }
    
}

// MARK: - UISearchBarDelegate
extension SearchTableViewController: UISearchBarDelegate {
    
    // MARK: - Methods
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.totalCount = 0
        self.pageCount = 1

        keyword = searchBar.text!
        guard let query = searchBar.text, query.trimmingCharacters(in: .whitespaces) != "" else {
            self.cellData.removeAll()
            self.tableView.reloadData()
            return
        }

        recentKeyword = KeywordCoreData.shared.setKeyword(item: keyword, usingContext: DataController.shared.viewContext)
    
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.reload(_:)), object: searchBar)
        perform(#selector(self.reload(_:)), with: searchBar, afterDelay: 0.2)
    }
    
    @objc func reload(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            self.configureTable(data: [SearchResults]())
        }
    }
    
}


// MARK: - UITableViewDelegate, UITableViewDataSource
extension SearchTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard self.cellData.isEmpty else {
            return self.cellData.count
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
  
        guard self.cellData.isEmpty else {
            return 88
        }
        return self.tableView.bounds.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 검색 결과값이 없을 때
        if self.cellData.isEmpty {
            self.tableView.setContentOffset(CGPoint.zero, animated: false)
            return tableView.dequeueReusableCell(withIdentifier: "EmptyTableViewCell", for: indexPath) as? EmptyTableViewCell ?? UITableViewCell()
        }
        else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableViewCell", for: indexPath) as? SearchTableViewCell {
               
                let replaced = self.cellData[indexPath.row].title?.replacingOccurrences(of: "<b>", with: " ")
                let newTitle = replaced?.replacingOccurrences(of: "</b>", with: " ")
                self.cellData[indexPath.row].title = newTitle
                
                cell.configure(data: self.cellData[indexPath.row])
                saveCellDataFromSearchKeyword(searchResult: self.cellData[indexPath.row])
                
                return cell
            }
            
            return UITableViewCell()
        }
    }
    
    
    // TableView 데이터 더 불러오기
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 데이터의 총 개수에서 10개를 뺀 값번째의 셀을 불러올 때 실행하고 데이터의 총 개수는 20개보다 커야 실행한다.
        if indexPath.row == self.cellData.count - 5 && self.totalCount > 20 {
            
            if self.pageCount <= (self.totalCount / 20) {
                self.pageCount += 1
                self.configureTable(data: self.cellData)
            }
            // 카운팅된 페이지 초기화
            else {
                self.pageCount = 1
            }
        }
    }
    
    //MARK: - get data index 
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if selectedItems.count > 2 {
            return nil
        }
        print("index array: \(indexPath.item)")
        return indexPath
    }

     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        guard self.cellData.count > 0 else {
            return
        }
           let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
           selectedCell.contentView.backgroundColor = .gray
           self.cellData[indexPath.row].isSelected = true
     }
       
       func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
           guard self.cellData.count > 0 else {
               return
           }
            let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
            selectedCell.contentView.backgroundColor = .clear
            self.cellData[indexPath.row].isSelected = false
       }
       
    //when select row, url website opened
    
//    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
//        let app = UIApplication.shared
//        app.open(URL(string: self.cellData[indexPath.row].link!)!, options: [:], completionHandler: nil)
//    }
}

