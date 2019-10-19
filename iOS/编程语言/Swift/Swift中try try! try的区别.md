# Swift中try try! try?的区别

- **try** 出现异常处理异常(必须在do catch中使用)
- **try?** 不处理异常,返回一个可选值类型,出现异常返回nil
- **try!** 不让异常继续传播,一旦出现异常程序停止,类似NSAssert()