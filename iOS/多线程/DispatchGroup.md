# DispatchGroup

## 栗子

```swift
func fetchAllPermission(completion: ((PermissionResponseModel) -> Void)?) {
        var requestUserPermissionError: Error?
        var requestPublicPermissionError: Error?
        let permissionRequestGroup = DispatchGroup()
        permissionRequestGroup.enter()
        fetchUserPermission {[weak self] (response, error) in
            guard let `self` = self else { return }
            defer {
                permissionRequestGroup.leave()
            }
            if let error = error {
                requestUserPermissionError = error
            }
            self.userPermission = response
        }
        permissionRequestGroup.enter()
        fetchPublicPermission {[weak self] (response, error) in
            guard let `self` = self else { return }
            defer {
                permissionRequestGroup.leave()
            }
            if let error = error {
                requestPublicPermissionError = error
            }
            self.publicPermission = response
        }
        permissionRequestGroup.notify(queue: DispatchQueue.main) {
            let permissionResponseModel = PermissionResponseModel(userPermission: self.userPermission,
                                                                  publicPermission: self.publicPermission,
                                                                  error: requestError)
            completion?(permissionResponseModel)
        }
    }
```

