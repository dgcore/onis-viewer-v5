import 'package:onis_viewer/core/models/entities/patient.dart' as entities;

///////////////////////////////////////////////////////////////////////
// J2kDecodeItem
///////////////////////////////////////////////////////////////////////

class OsJ2kDecodeItem {
  final int _decodingRes = -1;
  final WeakReference<entities.Image>? _wImage;
  final bool _isHighPriority;

  OsJ2kDecodeItem(entities.Image image, bool now)
      : _wImage = WeakReference<entities.Image>(image),
        _isHighPriority = now;

  get image => _wImage?.target;
  get series => image?.series;
  get study => series?.study;
  get patient => study?.patient;

  get isHighPriority => _isHighPriority;
  get decodingRes => _decodingRes;
}

///////////////////////////////////////////////////////////////////////
// OsJ2kDecoder
///////////////////////////////////////////////////////////////////////

class OsJ2kDecoder {
  //protected _th:Worker|null = null;
  /*bool _busy = false;
    protected _witem:OsWeakObject|null = null;
    protected _dm:OsDownloadManager|null = null;
    
    constructor(dm =OsDownloadManager) {
        super();
        _dm = dm;
        _th = Worker(URL('../../../j2k-decoder.worker', import.meta.url), { type: 'module' });
        _th.onmessage = ({ data }) => {
            _decoderMessageSuccess(data);
        };
    }

    protected _destroy():void {
        if (_witem) _witem.destroy();
        _witem = null;
        super._destroy();
    }

    public isBusy():boolean {
        return _busy;
    }

    public decode(item =OsJ2kDecodeItem, res =number):boolean {
        if (_busy || _witem || !_th) return false;
        let image:OsOpenedImage|null = item.getImage(false);
        if (!image) return false;
        let dcm:OsDicomFile|null = image.getDicomFile();
        let interData:OsIntermediatePixelData|null = dcm ? dcm.getIntermediatePixelData(0) : null;
        if (!interData) return false;
        if (res > interData.resIndex) return false;
        let param:any = {};
        param['encoded_data'] = interData.encodedData;
        param['resolution'] = res;
        _busy = true;
        _witem = item.getWeakObject();
        _th.postMessage(param);
        return true;
    }

    protected _decoderMessageSuccess(e =any) {
        let item:OsJ2kDecodeItem|null = _witem ? <OsJ2kDecodeItem>_witem.lock(false) : null;
        let image:OsOpenedImage|null = item ? item.getImage(false) : null;
        if (item && image) {
            let dcm:OsDicomFile|null = image.getDicomFile();
            if (dcm) {
                let interData:OsIntermediatePixelData|null = dcm.getIntermediatePixelData(0);
                if (interData) {
                    if ('decoding_error' in e) {
                        interData.decodingError = e.decoding_error;
                    }
                    else {
                        if (e.resolution > interData.currentRes) {
                            interData.currentRes = e.resolution;
                            interData.width = e.width;
                            interData.height = e.height;
                            interData.bits = e.bits;
                            interData.isSigned = e.signed;
                            interData.intermediatePixelData = Uint8Array(e.decoded_data.buffer);
                            if (_dm) _dm.onStreamDataDecoded(image);
                        }
                    }
                }
            }
            item.setDecodingResolution(-1);
        }
        //$scope.download_manager.on_received_decoded_stream($scope.download_manager.decoders[i], e);
        _busy = false;
        if (_witem) _witem.destroy();
        _witem = null;
        if (_dm) _dm.decodeNextStream();
    }

    protected _decoderMessageError(e =any) {
        alert("error");
    }*/
}
