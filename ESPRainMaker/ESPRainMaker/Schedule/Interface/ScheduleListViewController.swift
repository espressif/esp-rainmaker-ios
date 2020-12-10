// Copyright 2020 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  ScheduleListViewController.swift
//  ESPRainMaker
//

import UIKit

class ScheduleListViewController: UIViewController {
    @IBOutlet var addButton: UIButton!
    @IBOutlet var initialView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var editButton: BarButton!
    @IBOutlet var addScheduleButton: PrimaryButton!
    @IBOutlet var initialLabel: UILabel!
    @IBOutlet var networkIndicator: UIView!

    private let refreshControl = UIRefreshControl()
    var scheduleList: [String] = []

    // MARK: - Overriden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        showScheduleList()

        navigationController?.navigationBar.isHidden = true
        tableView.tableFooterView = UIView()

        refreshControl.addTarget(self, action: #selector(refreshScheduleList(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        tableView.refreshControl = refreshControl
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.isEditing = false
        editButton.setTitle("Edit", for: .normal)
        // Show UI based on scheudle list count
        if User.shared.updateDeviceList {
            User.shared.updateDeviceList = false
            Utility.showLoader(message: "", view: view)
            refreshScheduleList(self)
        } else {
            showScheduleList()
        }
        checkNetworkUpdate()
        NotificationCenter.default.addObserver(self, selector: #selector(checkNetworkUpdate), name: Notification.Name(Constants.networkUpdateNotification), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.networkUpdateNotification), object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == Constants.addScheduleSegue || segue.identifier == Constants.addNewScheduleSegue {
            ESPScheduler.shared.addSchedule()
            ESPScheduler.shared.configureDeviceForCurrentSchedule()
        }
    }

    @objc func checkNetworkUpdate() {
        DispatchQueue.main.async {
            if ESPNetworkMonitor.shared.isConnectedToNetwork {
                self.networkIndicator.isHidden = true
            } else {
                self.networkIndicator.isHidden = false
            }
        }
    }

    // MARK: -  IBActions

    @IBAction func editTableView(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
        sender.setTitle(tableView.isEditing ? "Done" : "Edit", for: .normal)
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func refreshScheduleList(_: Any) {
        refreshControl.endRefreshing()
        NetworkManager.shared.getNodes { nodes, error in
            Utility.hideLoader(view: self.view)
            if error != nil {
                DispatchQueue.main.async {
                    Utility.showToastMessage(view: self.view, message: "Network error: \(error?.description ?? "Something went wrong!!")")
                }
            } else {
                User.shared.associatedNodeList = nodes
                DispatchQueue.main.async {
                    self.showScheduleList()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }

    // MARK: Private Methods

    func showScheduleList() {
        getScheduleList()
        if ESPScheduler.shared.availableDevices.count < 1 {
            tableView.isHidden = true
            addButton.isHidden = true
            initialView.isHidden = false
            editButton.isHidden = true
            addButton.isHidden = true
            addScheduleButton.isHidden = true
            initialLabel.text = "No devices found with schedule feature."
        } else if scheduleList.count < 1 {
            tableView.isHidden = true
            addButton.isHidden = true
            initialView.isHidden = false
            editButton.isHidden = true
            addButton.isHidden = true
            addScheduleButton.isHidden = false
            initialLabel.text = "No list to show. Refresh or add a new schedule."
        } else {
            tableView.isHidden = false
            addButton.isHidden = false
            initialView.isHidden = true
            editButton.isHidden = false
        }
    }

    func getScheduleList() {
        scheduleList.removeAll()
        scheduleList = [String](ESPScheduler.shared.schedules.keys).sorted(by: <)
        tableView.reloadData()
    }
}

extension ScheduleListViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 70.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let scheduleVC = storyboard?.instantiateViewController(withIdentifier: "scheduleVC") as! ScheduleViewController
        ESPScheduler.shared.currentSchedule = ESPScheduler.shared.schedules[scheduleList[indexPath.section]]!
        ESPScheduler.shared.configureDeviceForCurrentSchedule()
        navigationController?.pushViewController(scheduleVC, animated: true)
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        return view
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertController = UIAlertController(title: "Remove", message: "Are you sure to remove this schedule?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { _ in
                DispatchQueue.main.async {
                    ESPScheduler.shared.deleteScheduleAt(key: self.scheduleList[indexPath.section], onView: self.view) { result in
                        if result {
                            Utility.showLoader(message: "", view: self.view)
                            self.refreshScheduleList(self)
                        }
                    }
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension ScheduleListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleListTVC", for: indexPath) as! ScheduleListTableViewCell
        let schedule = ESPScheduler.shared.schedules[scheduleList[indexPath.section]]!
        ESPScheduler.shared.currentSchedule = schedule
        ESPScheduler.shared.configureDeviceForCurrentSchedule()
        cell.schedule = schedule
        cell.scheduleLabel.text = schedule.name ?? ""
        cell.actionLabel.text = ESPScheduler.shared.getActionList()
        if schedule.trigger.days == 0 {
            cell.timerLabel.text = "Once at \(schedule.trigger.getTimeDetails())"
        } else if schedule.trigger.days == 127 {
            cell.timerLabel.text = "Daily at \(schedule.trigger.getTimeDetails())"
        } else {
            let dayDescription = schedule.week.getShortDescription()
            if dayDescription.lowercased() == "weekends" || dayDescription.lowercased() == "weekdays" {
                cell.timerLabel.text = "Every \(dayDescription.dropLast().lowercased()) at \(schedule.trigger.getTimeDetails())"
            } else {
                cell.timerLabel.text = "Every \(dayDescription) at \(schedule.trigger.getTimeDetails())"
            }
        }
        cell.scheduleSwitch.setOn(schedule.enabled, animated: true)
        cell.index = indexPath.section
        return cell
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func numberOfSections(in _: UITableView) -> Int {
        return scheduleList.count
    }
}
