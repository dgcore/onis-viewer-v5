class DownloadPerformance {
  /*protected _wsource:OsWeakObject|null = null;
    protected _timer:any = null;
    protected _tm:number = 0;
    protected _request:AsyncHttpRequest = new AsyncHttpRequest();
    protected _onis:Onis;
    public pingTime:number = 0;
    
    constructor(private onis:Onis, source:IPacsSource) {
        this._onis = onis;
        this._wsource = source.getWeakObject();
        this._timer = setInterval(this._checkPing.bind(this), 10000);
        this._checkPing();
    }

    public destroy():void {
        if (this._timer != null) {
            clearInterval(this._timer);
            this._timer = null;
        }
        if (this._wsource) this._wsource.destroy();
        if (this._request) this._request.cancel();
    }

    public getSource():IPacsSource|null {
        return this._wsource?<IPacsSource>this._wsource.lock(false):null;
    }

    protected _checkPing():void {
        if (this._request.inProcess()) return;
        let source:IPacsSource|null = this.getSource();
        if (source) {
            this._tm = performance.now();
            let request:AsyncHttpRequest|null = source.ping(this._onis, this._onPingResponse, this, null);
            if (request) this._request = request;
            else this._request = new AsyncHttpRequest();
        }
    }

    private _onPingResponse(status:boolean, data:any, cbkdata:any) {
        if (status == true) {
            if ('status' in data) {
                if (data.status === 0) {
                    this.pingTime = (performance.now() - this._tm) / 1000.0;
                }
            }
        }
    }
    */
}
