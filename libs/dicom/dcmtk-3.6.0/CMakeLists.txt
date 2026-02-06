

if(MSVC)
    remove_definitions(-DUNICODE)
    remove_definitions(-D_UNICODE)

#    add_definitions(-D_AFXDLL)

#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_DEBUG            ${CMAKE_C_FLAGS_DEBUG})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_MINSIZEREL       ${CMAKE_C_FLAGS_MINSIZEREL})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_RELEASE          ${CMAKE_C_FLAGS_RELEASE})
#    string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_RELWITHDEBINFO   ${CMAKE_C_FLAGS_RELWITHDEBINFO})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_DEBUG          ${CMAKE_CXX_FLAGS_DEBUG})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_MINSIZEREL     ${CMAKE_CXX_FLAGS_MINSIZEREL})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_RELEASE        ${CMAKE_CXX_FLAGS_RELEASE})
#    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})

#else(MSVC)

#    add_definitions(-D_ONIS_FOR_LINUX_)
    
endif(MSVC)

include_directories("config/include")
include_directories(STATIC "dcmdata/include")
include_directories(STATIC "dcmdata/include")
include_directories("dcmimage/include")
include_directories("dcmimgle/include")
include_directories("dcmjpeg/include")
include_directories("dcmjpls/include")
include_directories("dcmjpls/libcharls")
include_directories("dcmnet/include")
include_directories("dcmpstat/include")
include_directories("dcmqrdb/include")
include_directories("dcmsign/include")
include_directories("dcmsr/include")
include_directories("oflog/include")
include_directories("ofstd/include")
include_directories("../ijg8")
include_directories("../ijg12")
include_directories("../ijg16")
include_directories("../onis_j2k_kit/openjpeg-2.0.0/src/lib/openjp2")

add_library(dcmtk-3.6.0 STATIC "")

# Use modern C++ headers and define necessary macros for DCMTK
target_compile_definitions(dcmtk-3.6.0 PRIVATE
    USE_STD_CXX_INCLUDES
    HAVE_STD_NAMESPACE
    HAVE_SSTREAM
    ONIS_FOR_MAC
    HAVE_DECLARATION_SOCKLEN_T
    HAVE_DECLARATION_STRUCT_UTIMBUF
    HAVE_FORK
)

# Allow deprecated C++ features (register keyword, etc.) for DCMTK compatibility
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(dcmtk-3.6.0 PRIVATE -Wno-error=register -Wno-register)
endif()

target_sources(dcmtk-3.6.0
    PRIVATE
        dcmdata/libsrc/dcbytstr.cpp
        dcmdata/libsrc/dcchrstr.cpp 
        dcmdata/libsrc/dccodec.cpp 
        dcmdata/libsrc/dcdatset.cpp 
        dcmdata/libsrc/dcddirif.cpp 
        dcmdata/libsrc/dcdicdir.cpp 
        dcmdata/libsrc/dcdicent.cpp 
        dcmdata/libsrc/dcdict.cpp 
        dcmdata/libsrc/dcdictbi.cpp 
        dcmdata/libsrc/dcdictzz.cpp 
        dcmdata/libsrc/dcdirrec.cpp 
        dcmdata/libsrc/dcelem.cpp 
        dcmdata/libsrc/dcerror.cpp 
        dcmdata/libsrc/dcfilefo.cpp 
        dcmdata/libsrc/dchashdi.cpp 
        dcmdata/libsrc/dcistrma.cpp 
        dcmdata/libsrc/dcistrmb.cpp 
        dcmdata/libsrc/dcistrmf.cpp 
        dcmdata/libsrc/dcistrmz.cpp 
        dcmdata/libsrc/dcitem.cpp 
        dcmdata/libsrc/dclist.cpp 
        dcmdata/libsrc/dcmetinf.cpp 
        dcmdata/libsrc/dcobject.cpp 
        dcmdata/libsrc/dcostrma.cpp 
        dcmdata/libsrc/dcostrmb.cpp 
        dcmdata/libsrc/dcostrmf.cpp 
        dcmdata/libsrc/dcostrmz.cpp 
        dcmdata/libsrc/dcpath.cpp 
        dcmdata/libsrc/dcpcache.cpp 
        dcmdata/libsrc/dcpixel.cpp 
        dcmdata/libsrc/dcpixseq.cpp 
        dcmdata/libsrc/dcpxitem.cpp 
        dcmdata/libsrc/dcrleccd.cpp 
        dcmdata/libsrc/dcrlecce.cpp 
        dcmdata/libsrc/dcrlecp.cpp 
        dcmdata/libsrc/dcrledrg.cpp 
        dcmdata/libsrc/dcrleerg.cpp 
        dcmdata/libsrc/dcrlerp.cpp 
        dcmdata/libsrc/dcsequen.cpp 
        dcmdata/libsrc/dcstack.cpp 
        dcmdata/libsrc/dcswap.cpp 
        dcmdata/libsrc/dctag.cpp 
        dcmdata/libsrc/dctagkey.cpp 
        dcmdata/libsrc/dctypes.cpp 
        dcmdata/libsrc/dcuid.cpp 
        dcmdata/libsrc/dcvm.cpp 
        dcmdata/libsrc/dcvr.cpp 
        dcmdata/libsrc/dcvrae.cpp 
        dcmdata/libsrc/dcvras.cpp 
        dcmdata/libsrc/dcvrat.cpp 
        dcmdata/libsrc/dcvrcs.cpp 
        dcmdata/libsrc/dcvrda.cpp 
        dcmdata/libsrc/dcvrds.cpp 
        dcmdata/libsrc/dcvrdt.cpp 
        dcmdata/libsrc/dcvrfd.cpp 
        dcmdata/libsrc/dcvrfl.cpp 
        dcmdata/libsrc/dcvris.cpp 
        dcmdata/libsrc/dcvrlo.cpp 
        dcmdata/libsrc/dcvrlt.cpp 
        dcmdata/libsrc/dcvrobow.cpp 
        dcmdata/libsrc/dcvrof.cpp 
        dcmdata/libsrc/dcvrpn.cpp 
        dcmdata/libsrc/dcvrpobw.cpp 
        dcmdata/libsrc/dcvrsh.cpp 
        dcmdata/libsrc/dcvrsl.cpp 
        dcmdata/libsrc/dcvrss.cpp 
        dcmdata/libsrc/dcvrst.cpp 
        dcmdata/libsrc/dcvrtm.cpp 
        dcmdata/libsrc/dcvrui.cpp 
        dcmdata/libsrc/dcvrul.cpp 
        dcmdata/libsrc/dcvrulup.cpp 
        dcmdata/libsrc/dcvrus.cpp 
        dcmdata/libsrc/dcvrut.cpp 
        dcmdata/libsrc/dcwcache.cpp 
        dcmdata/libsrc/dcxfer.cpp 
        dcmdata/libsrc/vrscan.cpp 
        dcmdata/libsrc/vrscanl.cpp 
        dcmimage/libsrc/diargimg.cpp 
        dcmimage/libsrc/dicmyimg.cpp 
        dcmimage/libsrc/dicoimg.cpp 
        dcmimage/libsrc/dicoopx.cpp 
        dcmimage/libsrc/dicopx.cpp 
        dcmimage/libsrc/dihsvimg.cpp 
        dcmimage/libsrc/dilogger.cpp 
        dcmimage/libsrc/dipalimg.cpp 
        dcmimage/libsrc/dipipng.cpp 
        dcmimage/libsrc/dipitiff.cpp 
        dcmimage/libsrc/diqtctab.cpp 
        dcmimage/libsrc/diqtfs.cpp 
        dcmimage/libsrc/diqthash.cpp 
        dcmimage/libsrc/diqthitl.cpp 
        dcmimage/libsrc/diqtpbox.cpp 
        dcmimage/libsrc/diquant.cpp 
        dcmimage/libsrc/diregist.cpp 
        dcmimage/libsrc/dirgbimg.cpp 
        dcmimage/libsrc/diybrimg.cpp 
        dcmimage/libsrc/diyf2img.cpp 
        dcmimage/libsrc/diyp2img.cpp 
        dcmimgle/libsrc/dcmimage.cpp 
        dcmimgle/libsrc/dibaslut.cpp 
        dcmimgle/libsrc/diciefn.cpp 
        dcmimgle/libsrc/dicielut.cpp 
        dcmimgle/libsrc/didislut.cpp 
        dcmimgle/libsrc/didispfn.cpp 
        dcmimgle/libsrc/didocu.cpp 
        dcmimgle/libsrc/digsdfn.cpp 
        dcmimgle/libsrc/digsdlut.cpp 
        dcmimgle/libsrc/diimage.cpp 
        dcmimgle/libsrc/diinpx.cpp 
        dcmimgle/libsrc/diluptab.cpp 
        dcmimgle/libsrc/dimo1img.cpp 
        dcmimgle/libsrc/dimo2img.cpp 
        dcmimgle/libsrc/dimoimg.cpp 
        dcmimgle/libsrc/dimoimg3.cpp 
        dcmimgle/libsrc/dimoimg4.cpp 
        dcmimgle/libsrc/dimoimg5.cpp 
        dcmimgle/libsrc/dimomod.cpp 
        dcmimgle/libsrc/dimoopx.cpp 
        dcmimgle/libsrc/dimopx.cpp 
        dcmimgle/libsrc/diovdat.cpp 
        dcmimgle/libsrc/diovlay.cpp 
        dcmimgle/libsrc/diovlimg.cpp 
        dcmimgle/libsrc/diovpln.cpp 
        dcmimgle/libsrc/diutils.cpp 
        dcmjpeg/libsrc/ddpiimpl.cpp 
        dcmjpeg/libsrc/dipijpeg.cpp 
        dcmjpeg/libsrc/djcodecd.cpp 
        dcmjpeg/libsrc/djcodece.cpp 
        dcmjpeg/libsrc/djcparam.cpp 
        dcmjpeg/libsrc/djdec2k.cpp 
        dcmjpeg/libsrc/djdecbas.cpp 
        dcmjpeg/libsrc/djdecext.cpp 
        dcmjpeg/libsrc/djdeclol.cpp 
        dcmjpeg/libsrc/djdecode.cpp 
        dcmjpeg/libsrc/djdecpro.cpp 
        dcmjpeg/libsrc/djdecsps.cpp 
        dcmjpeg/libsrc/djdecsv1.cpp 
        dcmjpeg/libsrc/djdijg12.cpp 
        dcmjpeg/libsrc/djdijg16.cpp 
        dcmjpeg/libsrc/djdijg2k.cpp 
        dcmjpeg/libsrc/djdijg8.cpp 
        dcmjpeg/libsrc/djeijg12.cpp 
        dcmjpeg/libsrc/djeijg16.cpp 
        dcmjpeg/libsrc/djeijg2k.cpp 
        dcmjpeg/libsrc/djeijg8.cpp 
        dcmjpeg/libsrc/djenc2k.cpp 
        dcmjpeg/libsrc/djencbas.cpp 
        dcmjpeg/libsrc/djencext.cpp 
        dcmjpeg/libsrc/djenclol.cpp 
        dcmjpeg/libsrc/djencode.cpp 
        dcmjpeg/libsrc/djencpro.cpp 
        dcmjpeg/libsrc/djencsps.cpp 
        dcmjpeg/libsrc/djencsv1.cpp 
        dcmjpeg/libsrc/djrplol.cpp 
        dcmjpeg/libsrc/djrploss.cpp 
        dcmjpeg/libsrc/djutils.cpp 
        dcmjpeg/libsrc/opjbufferdata.cpp 
        dcmjpls/libcharls/header1.cpp 
        dcmjpls/libcharls/intrface1.cpp 
        dcmjpls/libcharls/jpegls1.cpp 
        dcmjpls/libsrc/djcodecd1.cpp 
        dcmjpls/libsrc/djcodece1.cpp 
        dcmjpls/libsrc/djcparam1.cpp 
        dcmjpls/libsrc/djdecode1.cpp 
        dcmjpls/libsrc/djencode1.cpp 
        dcmjpls/libsrc/djrparam1.cpp 
        dcmjpls/libsrc/djutils1.cpp 
        dcmnet/libsrc/assoc.cpp 
        dcmnet/libsrc/cond.cpp 
        dcmnet/libsrc/dcasccff.cpp 
        dcmnet/libsrc/dcasccfg.cpp 
        dcmnet/libsrc/dccfenmp.cpp 
        dcmnet/libsrc/dccfpcmp.cpp 
        dcmnet/libsrc/dccfprmp.cpp 
        dcmnet/libsrc/dccfrsmp.cpp 
        dcmnet/libsrc/dccftsmp.cpp 
        dcmnet/libsrc/dccfuidh.cpp 
        dcmnet/libsrc/dcmlayer.cpp 
        dcmnet/libsrc/dcmtrans.cpp 
        dcmnet/libsrc/dcompat.cpp 
        dcmnet/libsrc/dcuserid.cpp 
        dcmnet/libsrc/dfindscu.cpp 
        dcmnet/libsrc/dimcancl.cpp 
        dcmnet/libsrc/dimcmd.cpp 
        dcmnet/libsrc/dimdump.cpp 
        dcmnet/libsrc/dimecho.cpp 
        dcmnet/libsrc/dimfind.cpp 
        dcmnet/libsrc/dimget.cpp 
        dcmnet/libsrc/dimmove.cpp 
        dcmnet/libsrc/dimse.cpp 
        dcmnet/libsrc/dimstore.cpp 
        dcmnet/libsrc/diutil.cpp 
        dcmnet/libsrc/dul.cpp 
        dcmnet/libsrc/dulconst.cpp 
        dcmnet/libsrc/dulextra.cpp 
        dcmnet/libsrc/dulfsm.cpp 
        dcmnet/libsrc/dulparse.cpp 
        dcmnet/libsrc/dulpres.cpp 
        dcmnet/libsrc/extneg.cpp 
        dcmnet/libsrc/lst.cpp 
        dcmnet/libsrc/scp.cpp 
        dcmnet/libsrc/scu.cpp 
        dcmpstat/libsrc/dcmpstat.cpp 
        dcmpstat/libsrc/dviface.cpp 
        dcmpstat/libsrc/dvpsab.cpp 
        dcmpstat/libsrc/dvpsabl.cpp 
        dcmpstat/libsrc/dvpsal.cpp 
        dcmpstat/libsrc/dvpsall.cpp 
        dcmpstat/libsrc/dvpscf.cpp 
        dcmpstat/libsrc/dvpscu.cpp 
        dcmpstat/libsrc/dvpscul.cpp 
        dcmpstat/libsrc/dvpsda.cpp 
        dcmpstat/libsrc/dvpsdal.cpp 
        dcmpstat/libsrc/dvpsfs.cpp 
        dcmpstat/libsrc/dvpsga.cpp 
        dcmpstat/libsrc/dvpsgal.cpp 
        dcmpstat/libsrc/dvpsgl.cpp 
        dcmpstat/libsrc/dvpsgll.cpp 
        dcmpstat/libsrc/dvpsgr.cpp 
        dcmpstat/libsrc/dvpsgrl.cpp 
        dcmpstat/libsrc/dvpshlp.cpp 
        dcmpstat/libsrc/dvpsib.cpp 
        dcmpstat/libsrc/dvpsibl.cpp 
        dcmpstat/libsrc/dvpsmsg.cpp 
        dcmpstat/libsrc/dvpsov.cpp 
        dcmpstat/libsrc/dvpsovl.cpp 
        dcmpstat/libsrc/dvpspl.cpp 
        dcmpstat/libsrc/dvpspl2.cpp 
        dcmpstat/libsrc/dvpspll.cpp 
        dcmpstat/libsrc/dvpspr.cpp 
        dcmpstat/libsrc/dvpsprt.cpp 
        dcmpstat/libsrc/dvpsri.cpp 
        dcmpstat/libsrc/dvpsril.cpp 
        dcmpstat/libsrc/dvpsrs.cpp 
        dcmpstat/libsrc/dvpsrsl.cpp 
        dcmpstat/libsrc/dvpssp.cpp 
        dcmpstat/libsrc/dvpsspl.cpp 
        dcmpstat/libsrc/dvpssv.cpp 
        dcmpstat/libsrc/dvpssvl.cpp 
        dcmpstat/libsrc/dvpstat.cpp 
        dcmpstat/libsrc/dvpstx.cpp 
        dcmpstat/libsrc/dvpstxl.cpp 
        dcmpstat/libsrc/dvpsvl.cpp 
        dcmpstat/libsrc/dvpsvll.cpp 
        dcmpstat/libsrc/dvpsvw.cpp 
        dcmpstat/libsrc/dvpsvwl.cpp 
        dcmpstat/libsrc/dvsighdl.cpp 
        dcmqrdb/libsrc/dcmqrcbf.cpp 
        dcmqrdb/libsrc/dcmqrcbg.cpp 
        dcmqrdb/libsrc/dcmqrcbm.cpp 
        dcmqrdb/libsrc/dcmqrcbs.cpp 
        dcmqrdb/libsrc/dcmqrcnf.cpp 
        dcmqrdb/libsrc/dcmqrdbi.cpp 
        dcmqrdb/libsrc/dcmqrdbs.cpp 
        dcmqrdb/libsrc/dcmqropt.cpp 
        dcmqrdb/libsrc/dcmqrptb.cpp 
        dcmqrdb/libsrc/dcmqrsrv.cpp 
        dcmqrdb/libsrc/dcmqrtis.cpp 
        dcmsign/libsrc/dcsignat.cpp 
        dcmsign/libsrc/siautopr.cpp 
        dcmsign/libsrc/sibrsapr.cpp 
        dcmsign/libsrc/sicert.cpp 
        dcmsign/libsrc/sicertvf.cpp 
        dcmsign/libsrc/sicreapr.cpp 
        dcmsign/libsrc/sidsa.cpp 
        dcmsign/libsrc/simaccon.cpp 
        dcmsign/libsrc/simd5.cpp 
        dcmsign/libsrc/sinullpr.cpp 
        dcmsign/libsrc/siprivat.cpp 
        dcmsign/libsrc/siripemd.cpp 
        dcmsign/libsrc/sirsa.cpp 
        dcmsign/libsrc/sisha1.cpp 
        dcmsign/libsrc/sisprof.cpp 
        dcmsign/libsrc/sitypes.cpp 
        dcmsr/libsrc/dsrbascc.cpp 
        dcmsr/libsrc/dsrchecc.cpp 
        dcmsr/libsrc/dsrcitem.cpp 
        dcmsr/libsrc/dsrcodtn.cpp 
        dcmsr/libsrc/dsrcodvl.cpp 
        dcmsr/libsrc/dsrcolcc.cpp 
        dcmsr/libsrc/dsrcomcc.cpp 
        dcmsr/libsrc/dsrcomtn.cpp 
        dcmsr/libsrc/dsrcomvl.cpp 
        dcmsr/libsrc/dsrcontn.cpp 
        dcmsr/libsrc/dsrcsidl.cpp 
        dcmsr/libsrc/dsrdattn.cpp 
        dcmsr/libsrc/dsrdoc.cpp 
        dcmsr/libsrc/dsrdoctn.cpp 
        dcmsr/libsrc/dsrdoctr.cpp 
        dcmsr/libsrc/dsrdtitn.cpp 
        dcmsr/libsrc/dsrenhcc.cpp 
        dcmsr/libsrc/dsrimgfr.cpp 
        dcmsr/libsrc/dsrimgtn.cpp 
        dcmsr/libsrc/dsrimgvl.cpp 
        dcmsr/libsrc/dsrimpcc.cpp 
        dcmsr/libsrc/dsriodcc.cpp 
        dcmsr/libsrc/dsrkeycc.cpp 
        dcmsr/libsrc/dsrmaccc.cpp 
        dcmsr/libsrc/dsrmamcc.cpp 
        dcmsr/libsrc/dsrnumtn.cpp 
        dcmsr/libsrc/dsrnumvl.cpp 
        dcmsr/libsrc/dsrpnmtn.cpp 
        dcmsr/libsrc/dsrprocc.cpp 
        dcmsr/libsrc/dsrreftn.cpp 
        dcmsr/libsrc/dsrsc3gr.cpp 
        dcmsr/libsrc/dsrsc3tn.cpp 
        dcmsr/libsrc/dsrsc3vl.cpp 
        dcmsr/libsrc/dsrscogr.cpp 
        dcmsr/libsrc/dsrscotn.cpp 
        dcmsr/libsrc/dsrscovl.cpp 
        dcmsr/libsrc/dsrsoprf.cpp 
        dcmsr/libsrc/dsrspecc.cpp 
        dcmsr/libsrc/dsrstrvl.cpp 
        dcmsr/libsrc/dsrtcodt.cpp 
        dcmsr/libsrc/dsrtcosp.cpp 
        dcmsr/libsrc/dsrtcotn.cpp 
        dcmsr/libsrc/dsrtcoto.cpp 
        dcmsr/libsrc/dsrtcovl.cpp 
        dcmsr/libsrc/dsrtextn.cpp 
        dcmsr/libsrc/dsrtimtn.cpp 
        dcmsr/libsrc/dsrtncsr.cpp 
        dcmsr/libsrc/dsrtree.cpp 
        dcmsr/libsrc/dsrtypes.cpp 
        dcmsr/libsrc/dsruidtn.cpp 
        dcmsr/libsrc/dsrwavch.cpp 
        dcmsr/libsrc/dsrwavtn.cpp 
        dcmsr/libsrc/dsrwavvl.cpp 
        dcmsr/libsrc/dsrxmlc.cpp 
        dcmsr/libsrc/dsrxmld.cpp 
        dcmsr/libsrc/dsrxrdcc.cpp 
        oflog/libsrc/apndimpl.cpp 
        oflog/libsrc/appender.cpp 
        oflog/libsrc/config.cpp 
        oflog/libsrc/consap.cpp 
        oflog/libsrc/factory.cpp 
        oflog/libsrc/fileap.cpp 
        oflog/libsrc/filter.cpp 
        oflog/libsrc/globinit.cpp 
        oflog/libsrc/hierarchy.cpp 
        oflog/libsrc/hierlock.cpp 
        oflog/libsrc/layout.cpp 
        oflog/libsrc/lloguser.cpp 
        oflog/libsrc/logevent.cpp 
        oflog/libsrc/logger.cpp 
        oflog/libsrc/logimpl.cpp 
        oflog/libsrc/loglevel.cpp 
        oflog/libsrc/loglog.cpp 
        oflog/libsrc/ndc.cpp 
        oflog/libsrc/ntelogap.cpp 
        oflog/libsrc/nullap.cpp 
        oflog/libsrc/objreg.cpp 
        oflog/libsrc/oflog.cpp 
        oflog/libsrc/patlay.cpp 
        oflog/libsrc/pointer.cpp 
        oflog/libsrc/property.cpp 
        oflog/libsrc/rootlog.cpp 
        oflog/libsrc/sleep.cpp 
        oflog/libsrc/sockbuff.cpp 
        oflog/libsrc/socket.cpp 
        oflog/libsrc/socketap.cpp 
        oflog/libsrc/strhelp.cpp 
        oflog/libsrc/syncprims.cpp 
        oflog/libsrc/syslogap.cpp 
        oflog/libsrc/threads.cpp 
        oflog/libsrc/timehelp.cpp 
        oflog/libsrc/winconap.cpp 
        oflog/libsrc/windebap.cpp 
        ofstd/libsrc/ofcmdln.cpp 
        ofstd/libsrc/ofconapp.cpp 
        ofstd/libsrc/ofcond.cpp 
        ofstd/libsrc/ofconfig.cpp 
        ofstd/libsrc/ofconsol.cpp 
        ofstd/libsrc/ofcrc32.cpp 
        ofstd/libsrc/ofdate.cpp 
        ofstd/libsrc/ofdatime.cpp 
        ofstd/libsrc/offname.cpp 
        ofstd/libsrc/oflist.cpp 
        ofstd/libsrc/ofstd.cpp 
        ofstd/libsrc/ofstring.cpp 
        ofstd/libsrc/ofthread.cpp 
        ofstd/libsrc/oftime.cpp 
)

if(MSVC)
    target_sources(dcmtk-3.6.0
        PRIVATE
            oflog/libsrc/winsock.cpp 
    )
endif(MSVC)

#target_sources(dcmtk-3.6.0 
    #STATIC "dcmdata/libsrc/dcbytstr.cpp" 
    #STATIC "dcmdata/libsrc/dcchrstr.cpp" 
    #STATIC "dcmdata/libsrc/dccodec.cpp" 
    #STATIC "dcmdata/libsrc/dcdatset.cpp" 
    #STATIC "dcmdata/libsrc/dcddirif.cpp" 
    #STATIC "dcmdata/libsrc/dcdicdir.cpp" 
    #STATIC "dcmdata/libsrc/dcdicent.cpp" 
    #STATIC "dcmdata/libsrc/dcdict.cpp" 
    #STATIC "dcmdata/libsrc/dcdictbi.cpp" 
    #STATIC "dcmdata/libsrc/dcdictzz.cpp" 
    #STATIC "dcmdata/libsrc/dcdirrec.cpp" 
    #STATIC "dcmdata/libsrc/dcelem.cpp" 
    #STATIC "dcmdata/libsrc/dcerror.cpp" 
    #STATIC "dcmdata/libsrc/dcfilefo.cpp" 
    #STATIC "dcmdata/libsrc/dchashdi.cpp" 
    #STATIC "dcmdata/libsrc/dcistrma.cpp" 
    #STATIC "dcmdata/libsrc/dcistrmb.cpp" 
    #STATIC "dcmdata/libsrc/dcistrmf.cpp" 
    #STATIC "dcmdata/libsrc/dcistrmz.cpp" 
    #STATIC "dcmdata/libsrc/dcitem.cpp" 
    #STATIC "dcmdata/libsrc/dclist.cpp" 
    #STATIC "dcmdata/libsrc/dcmetinf.cpp" 
    #STATIC "dcmdata/libsrc/dcobject.cpp" 
    #STATIC "dcmdata/libsrc/dcostrma.cpp" 
    #STATIC "dcmdata/libsrc/dcostrmb.cpp" 
    #STATIC "dcmdata/libsrc/dcostrmf.cpp" 
    #STATIC "dcmdata/libsrc/dcostrmz.cpp" 
    #STATIC "dcmdata/libsrc/dcpath.cpp" 
    #STATIC "dcmdata/libsrc/dcpcache.cpp" 
    #STATIC "dcmdata/libsrc/dcpixel.cpp" 
    #STATIC "dcmdata/libsrc/dcpixseq.cpp" 
    #STATIC "dcmdata/libsrc/dcpxitem.cpp" 
    #STATIC "dcmdata/libsrc/dcrleccd.cpp" 
    #STATIC "dcmdata/libsrc/dcrlecce.cpp" 
    #STATIC "dcmdata/libsrc/dcrlecp.cpp" 
    #STATIC "dcmdata/libsrc/dcrledrg.cpp" 
    #STATIC "dcmdata/libsrc/dcrleerg.cpp" 
    #STATIC "dcmdata/libsrc/dcrlerp.cpp" 
    #STATIC "dcmdata/libsrc/dcsequen.cpp" 
    #STATIC "dcmdata/libsrc/dcstack.cpp" 
    #STATIC "dcmdata/libsrc/dcswap.cpp" 
    #STATIC "dcmdata/libsrc/dctag.cpp" 
    #STATIC "dcmdata/libsrc/dctagkey.cpp" 
    #STATIC "dcmdata/libsrc/dctypes.cpp" 
    #STATIC "dcmdata/libsrc/dcuid.cpp" 
    #STATIC "dcmdata/libsrc/dcvm.cpp" 
    #STATIC "dcmdata/libsrc/dcvr.cpp" 
    #STATIC "dcmdata/libsrc/dcvrae.cpp" 
    #STATIC "dcmdata/libsrc/dcvras.cpp" 
    #STATIC "dcmdata/libsrc/dcvrat.cpp" 
    #STATIC "dcmdata/libsrc/dcvrcs.cpp" 
    #STATIC "dcmdata/libsrc/dcvrda.cpp" 
    #STATIC "dcmdata/libsrc/dcvrds.cpp" 
    #STATIC "dcmdata/libsrc/dcvrdt.cpp" 
    #STATIC "dcmdata/libsrc/dcvrfd.cpp" 
    #STATIC "dcmdata/libsrc/dcvrfl.cpp" 
    #STATIC "dcmdata/libsrc/dcvris.cpp" 
    #STATIC "dcmdata/libsrc/dcvrlo.cpp" 
    #STATIC "dcmdata/libsrc/dcvrlt.cpp" 
    #STATIC "dcmdata/libsrc/dcvrobow.cpp" 
    #STATIC "dcmdata/libsrc/dcvrof.cpp" 
    #STATIC "dcmdata/libsrc/dcvrpn.cpp" 
    #STATIC "dcmdata/libsrc/dcvrpobw.cpp" 
    #STATIC "dcmdata/libsrc/dcvrsh.cpp" 
    #STATIC "dcmdata/libsrc/dcvrsl.cpp" 
    #STATIC "dcmdata/libsrc/dcvrss.cpp" 
    #STATIC "dcmdata/libsrc/dcvrst.cpp" 
    #STATIC "dcmdata/libsrc/dcvrtm.cpp" 
    #STATIC "dcmdata/libsrc/dcvrui.cpp" 
    #STATIC "dcmdata/libsrc/dcvrul.cpp" 
    #STATIC "dcmdata/libsrc/dcvrulup.cpp" 
    #STATIC "dcmdata/libsrc/dcvrus.cpp" 
    #STATIC "dcmdata/libsrc/dcvrut.cpp" 
    #STATIC "dcmdata/libsrc/dcwcache.cpp" 
    #STATIC "dcmdata/libsrc/dcxfer.cpp" 
    #STATIC "dcmdata/libsrc/vrscan.cpp" 
    #STATIC "dcmdata/libsrc/vrscanl.cpp" 
    #STATIC "dcmimage/libsrc/diargimg.cpp" 
    #STATIC "dcmimage/libsrc/dicmyimg.cpp" 
    #STATIC "dcmimage/libsrc/dicoimg.cpp" 
    #STATIC "dcmimage/libsrc/dicoopx.cpp" 
    #STATIC "dcmimage/libsrc/dicopx.cpp" 
    #STATIC "dcmimage/libsrc/dihsvimg.cpp" 
    #STATIC "dcmimage/libsrc/dilogger.cpp" 
    #STATIC "dcmimage/libsrc/dipalimg.cpp" 
    #STATIC "dcmimage/libsrc/dipipng.cpp" 
    #STATIC "dcmimage/libsrc/dipitiff.cpp" 
    #STATIC "dcmimage/libsrc/diqtctab.cpp" 
    #STATIC "dcmimage/libsrc/diqtfs.cpp" 
    #STATIC "dcmimage/libsrc/diqthash.cpp" 
    #STATIC "dcmimage/libsrc/diqthitl.cpp" 
    #STATIC "dcmimage/libsrc/diqtpbox.cpp" 
    #STATIC "dcmimage/libsrc/diquant.cpp" 
    #STATIC "dcmimage/libsrc/diregist.cpp" 
    #STATIC "dcmimage/libsrc/dirgbimg.cpp" 
    #STATIC "dcmimage/libsrc/diybrimg.cpp" 
    #STATIC "dcmimage/libsrc/diyf2img.cpp" 
    #STATIC "dcmimage/libsrc/diyp2img.cpp" 
    #STATIC "dcmimgle/libsrc/dcmimage.cpp" 
    #STATIC "dcmimgle/libsrc/dibaslut.cpp" 
    #STATIC "dcmimgle/libsrc/diciefn.cpp" 
    #STATIC "dcmimgle/libsrc/dicielut.cpp" 
    #STATIC "dcmimgle/libsrc/didislut.cpp" 
    #STATIC "dcmimgle/libsrc/didispfn.cpp" 
    #STATIC "dcmimgle/libsrc/didocu.cpp" 
    #STATIC "dcmimgle/libsrc/digsdfn.cpp" 
    #STATIC "dcmimgle/libsrc/digsdlut.cpp" 
    #STATIC "dcmimgle/libsrc/diimage.cpp" 
    #STATIC "dcmimgle/libsrc/diinpx.cpp" 
    #STATIC "dcmimgle/libsrc/diluptab.cpp" 
    #STATIC "dcmimgle/libsrc/dimo1img.cpp" 
    #STATIC "dcmimgle/libsrc/dimo2img.cpp" 
    #STATIC "dcmimgle/libsrc/dimoimg.cpp" 
    #STATIC "dcmimgle/libsrc/dimoimg3.cpp" 
    #STATIC "dcmimgle/libsrc/dimoimg4.cpp" 
    #STATIC "dcmimgle/libsrc/dimoimg5.cpp" 
    #STATIC "dcmimgle/libsrc/dimomod.cpp" 
    #STATIC "dcmimgle/libsrc/dimoopx.cpp" 
    #STATIC "dcmimgle/libsrc/dimopx.cpp" 
    #STATIC "dcmimgle/libsrc/diovdat.cpp" 
    #STATIC "dcmimgle/libsrc/diovlay.cpp" 
    #STATIC "dcmimgle/libsrc/diovlimg.cpp" 
    #STATIC "dcmimgle/libsrc/diovpln.cpp" 
    #STATIC "dcmimgle/libsrc/diutils.cpp" 
    #STATIC "dcmjpeg/libsrc/ddpiimpl.cpp" 
    #STATIC "dcmjpeg/libsrc/dipijpeg.cpp" 
    #STATIC "dcmjpeg/libsrc/djcodecd.cpp" 
    #STATIC "dcmjpeg/libsrc/djcodece.cpp" 
    #STATIC "dcmjpeg/libsrc/djcparam.cpp" 
    #STATIC "dcmjpeg/libsrc/djdec2k.cpp" 
    #STATIC "dcmjpeg/libsrc/djdecbas.cpp" 
    #STATIC "dcmjpeg/libsrc/djdecext.cpp" 
    #STATIC "dcmjpeg/libsrc/djdeclol.cpp" 
    #STATIC "dcmjpeg/libsrc/djdecode.cpp" 
    #STATIC "dcmjpeg/libsrc/djdecpro.cpp" 
    #STATIC "dcmjpeg/libsrc/djdecsps.cpp" 
    #STATIC "dcmjpeg/libsrc/djdecsv1.cpp" 
    #STATIC "dcmjpeg/libsrc/djdijg12.cpp" 
    #STATIC "dcmjpeg/libsrc/djdijg16.cpp" 
    #STATIC "dcmjpeg/libsrc/djdijg2k.cpp" 
    #STATIC "dcmjpeg/libsrc/djdijg8.cpp" 
    #STATIC "dcmjpeg/libsrc/djeijg12.cpp" 
    #STATIC "dcmjpeg/libsrc/djeijg16.cpp" 
    #STATIC "dcmjpeg/libsrc/djeijg2k.cpp" 
    #STATIC "dcmjpeg/libsrc/djeijg8.cpp" 
    #STATIC "dcmjpeg/libsrc/djenc2k.cpp" 
    #STATIC "dcmjpeg/libsrc/djencbas.cpp" 
    #STATIC "dcmjpeg/libsrc/djencext.cpp" 
    #STATIC "dcmjpeg/libsrc/djenclol.cpp" 
    #STATIC "dcmjpeg/libsrc/djencode.cpp" 
    #STATIC "dcmjpeg/libsrc/djencpro.cpp" 
    #STATIC "dcmjpeg/libsrc/djencsps.cpp" 
    #STATIC "dcmjpeg/libsrc/djencsv1.cpp" 
    #STATIC "dcmjpeg/libsrc/djrplol.cpp" 
    #STATIC "dcmjpeg/libsrc/djrploss.cpp" 
    #STATIC "dcmjpeg/libsrc/djutils.cpp" 
    #STATIC "dcmjpeg/libsrc/opjbufferdata.cpp" 
    #STATIC "dcmjpls/libcharls/header1.cpp" 
    #STATIC "dcmjpls/libcharls/intrface1.cpp" 
    #STATIC "dcmjpls/libcharls/jpegls1.cpp" 
    #STATIC "dcmjpls/libsrc/djcodecd1.cpp" 
    #STATIC "dcmjpls/libsrc/djcodece1.cpp" 
    #STATIC "dcmjpls/libsrc/djcparam1.cpp" 
    #STATIC "dcmjpls/libsrc/djdecode1.cpp" 
    #STATIC "dcmjpls/libsrc/djencode1.cpp" 
    #STATIC "dcmjpls/libsrc/djrparam1.cpp" 
    #STATIC "dcmjpls/libsrc/djutils1.cpp" 
    #STATIC "dcmnet/libsrc/assoc.cpp" 
    #STATIC "dcmnet/libsrc/cond.cpp" 
    #STATIC "dcmnet/libsrc/dcasccff.cpp" 
    #STATIC "dcmnet/libsrc/dcasccfg.cpp" 
    #STATIC "dcmnet/libsrc/dccfenmp.cpp" 
    #STATIC "dcmnet/libsrc/dccfpcmp.cpp" 
    #STATIC "dcmnet/libsrc/dccfprmp.cpp" 
    #STATIC "dcmnet/libsrc/dccfrsmp.cpp" 
    #STATIC "dcmnet/libsrc/dccftsmp.cpp" 
    #STATIC "dcmnet/libsrc/dccfuidh.cpp" 
    #STATIC "dcmnet/libsrc/dcmlayer.cpp" 
    #STATIC "dcmnet/libsrc/dcmtrans.cpp" 
    #STATIC "dcmnet/libsrc/dcompat.cpp" 
    #STATIC "dcmnet/libsrc/dcuserid.cpp" 
    #STATIC "dcmnet/libsrc/dfindscu.cpp" 
    #STATIC "dcmnet/libsrc/dimcancl.cpp" 
    #STATIC "dcmnet/libsrc/dimcmd.cpp" 
    #STATIC "dcmnet/libsrc/dimdump.cpp" 
    #STATIC "dcmnet/libsrc/dimecho.cpp" 
    #STATIC "dcmnet/libsrc/dimfind.cpp" 
    #STATIC "dcmnet/libsrc/dimget.cpp" 
    #STATIC "dcmnet/libsrc/dimmove.cpp" 
    #STATIC "dcmnet/libsrc/dimse.cpp" 
    #STATIC "dcmnet/libsrc/dimstore.cpp" 
    #STATIC "dcmnet/libsrc/diutil.cpp" 
    #STATIC "dcmnet/libsrc/dul.cpp" 
    #STATIC "dcmnet/libsrc/dulconst.cpp" 
    #STATIC "dcmnet/libsrc/dulextra.cpp" 
    #STATIC "dcmnet/libsrc/dulfsm.cpp" 
    #STATIC "dcmnet/libsrc/dulparse.cpp" 
    #STATIC "dcmnet/libsrc/dulpres.cpp" 
    #STATIC "dcmnet/libsrc/extneg.cpp" 
    #STATIC "dcmnet/libsrc/lst.cpp" 
    #STATIC "dcmnet/libsrc/scp.cpp" 
    #STATIC "dcmnet/libsrc/scu.cpp" 
    #STATIC "dcmpstat/libsrc/dcmpstat.cpp" 
    #STATIC "dcmpstat/libsrc/dviface.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsab.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsabl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsal.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsall.cpp" 
    #STATIC "dcmpstat/libsrc/dvpscf.cpp" 
    #STATIC "dcmpstat/libsrc/dvpscu.cpp" 
    #STATIC "dcmpstat/libsrc/dvpscul.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsda.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsdal.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsfs.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsga.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsgal.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsgl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsgll.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsgr.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsgrl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpshlp.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsib.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsibl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsmsg.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsov.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsovl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpspl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpspl2.cpp" 
    #STATIC "dcmpstat/libsrc/dvpspll.cpp" 
    #STATIC "dcmpstat/libsrc/dvpspr.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsprt.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsri.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsril.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsrs.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsrsl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpssp.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsspl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpssv.cpp" 
    #STATIC "dcmpstat/libsrc/dvpssvl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpstat.cpp" 
    #STATIC "dcmpstat/libsrc/dvpstx.cpp" 
    #STATIC "dcmpstat/libsrc/dvpstxl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsvl.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsvll.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsvw.cpp" 
    #STATIC "dcmpstat/libsrc/dvpsvwl.cpp" 
    #STATIC "dcmpstat/libsrc/dvsighdl.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrcbf.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrcbg.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrcbm.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrcbs.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrcnf.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrdbi.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrdbs.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqropt.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrptb.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrsrv.cpp" 
    #STATIC "dcmqrdb/libsrc/dcmqrtis.cpp" 
    #STATIC "dcmsign/libsrc/dcsignat.cpp" 
    #STATIC "dcmsign/libsrc/siautopr.cpp" 
    #STATIC "dcmsign/libsrc/sibrsapr.cpp" 
    #STATIC "dcmsign/libsrc/sicert.cpp" 
    #STATIC "dcmsign/libsrc/sicertvf.cpp" 
    #STATIC "dcmsign/libsrc/sicreapr.cpp" 
    #STATIC "dcmsign/libsrc/sidsa.cpp" 
    #STATIC "dcmsign/libsrc/simaccon.cpp" 
    #STATIC "dcmsign/libsrc/simd5.cpp" 
    #STATIC "dcmsign/libsrc/sinullpr.cpp" 
    #STATIC "dcmsign/libsrc/siprivat.cpp" 
    #STATIC "dcmsign/libsrc/siripemd.cpp" 
    #STATIC "dcmsign/libsrc/sirsa.cpp" 
    #STATIC "dcmsign/libsrc/sisha1.cpp" 
    #STATIC "dcmsign/libsrc/sisprof.cpp" 
    #STATIC "dcmsign/libsrc/sitypes.cpp" 
    #STATIC "dcmsr/libsrc/dsrbascc.cpp" 
    #STATIC "dcmsr/libsrc/dsrchecc.cpp" 
    #STATIC "dcmsr/libsrc/dsrcitem.cpp" 
    #STATIC "dcmsr/libsrc/dsrcodtn.cpp" 
    #STATIC "dcmsr/libsrc/dsrcodvl.cpp" 
    #STATIC "dcmsr/libsrc/dsrcolcc.cpp" 
    #STATIC "dcmsr/libsrc/dsrcomcc.cpp" 
    #STATIC "dcmsr/libsrc/dsrcomtn.cpp" 
    #STATIC "dcmsr/libsrc/dsrcomvl.cpp" 
    #STATIC "dcmsr/libsrc/dsrcontn.cpp" 
    #STATIC "dcmsr/libsrc/dsrcsidl.cpp" 
    #STATIC "dcmsr/libsrc/dsrdattn.cpp" 
    #STATIC "dcmsr/libsrc/dsrdoc.cpp" 
    #STATIC "dcmsr/libsrc/dsrdoctn.cpp" 
    #STATIC "dcmsr/libsrc/dsrdoctr.cpp" 
    #STATIC "dcmsr/libsrc/dsrdtitn.cpp" 
    #STATIC "dcmsr/libsrc/dsrenhcc.cpp" 
    #STATIC "dcmsr/libsrc/dsrimgfr.cpp" 
    #STATIC "dcmsr/libsrc/dsrimgtn.cpp" 
    #STATIC "dcmsr/libsrc/dsrimgvl.cpp" 
    #STATIC "dcmsr/libsrc/dsrimpcc.cpp" 
    #STATIC "dcmsr/libsrc/dsriodcc.cpp" 
    #STATIC "dcmsr/libsrc/dsrkeycc.cpp" 
    #STATIC "dcmsr/libsrc/dsrmaccc.cpp" 
    #STATIC "dcmsr/libsrc/dsrmamcc.cpp" 
    #STATIC "dcmsr/libsrc/dsrnumtn.cpp" 
    #STATIC "dcmsr/libsrc/dsrnumvl.cpp" 
    #STATIC "dcmsr/libsrc/dsrpnmtn.cpp" 
    #STATIC "dcmsr/libsrc/dsrprocc.cpp" 
    #STATIC "dcmsr/libsrc/dsrreftn.cpp" 
    #STATIC "dcmsr/libsrc/dsrsc3gr.cpp" 
    #STATIC "dcmsr/libsrc/dsrsc3tn.cpp" 
    #STATIC "dcmsr/libsrc/dsrsc3vl.cpp" 
    #STATIC "dcmsr/libsrc/dsrscogr.cpp" 
    #STATIC "dcmsr/libsrc/dsrscotn.cpp" 
    #STATIC "dcmsr/libsrc/dsrscovl.cpp" 
    #STATIC "dcmsr/libsrc/dsrsoprf.cpp" 
    #STATIC "dcmsr/libsrc/dsrspecc.cpp" 
    #STATIC "dcmsr/libsrc/dsrstrvl.cpp" 
    #STATIC "dcmsr/libsrc/dsrtcodt.cpp" 
    #STATIC "dcmsr/libsrc/dsrtcosp.cpp" 
    #STATIC "dcmsr/libsrc/dsrtcotn.cpp" 
    #STATIC "dcmsr/libsrc/dsrtcoto.cpp" 
    #STATIC "dcmsr/libsrc/dsrtcovl.cpp" 
    #STATIC "dcmsr/libsrc/dsrtextn.cpp" 
    #STATIC "dcmsr/libsrc/dsrtimtn.cpp" 
    #STATIC "dcmsr/libsrc/dsrtncsr.cpp" 
    #STATIC "dcmsr/libsrc/dsrtree.cpp" 
    #STATIC "dcmsr/libsrc/dsrtypes.cpp" 
    #STATIC "dcmsr/libsrc/dsruidtn.cpp" 
    #STATIC "dcmsr/libsrc/dsrwavch.cpp" 
    #STATIC "dcmsr/libsrc/dsrwavtn.cpp" 
    #STATIC "dcmsr/libsrc/dsrwavvl.cpp" 
    #STATIC "dcmsr/libsrc/dsrxmlc.cpp" 
    #STATIC "dcmsr/libsrc/dsrxmld.cpp" 
    #STATIC "dcmsr/libsrc/dsrxrdcc.cpp" 
    #STATIC "oflog/libsrc/apndimpl.cpp" 
    #STATIC "oflog/libsrc/appender.cpp" 
    #STATIC "oflog/libsrc/config.cpp" 
    #STATIC "oflog/libsrc/consap.cpp" 
    #STATIC "oflog/libsrc/factory.cpp" 
    #STATIC "oflog/libsrc/fileap.cpp" 
    #STATIC "oflog/libsrc/filter.cpp" 
    #STATIC "oflog/libsrc/globinit.cpp" 
    #STATIC "oflog/libsrc/hierarchy.cpp" 
    #STATIC "oflog/libsrc/hierlock.cpp" 
    #STATIC "oflog/libsrc/layout.cpp" 
    #STATIC "oflog/libsrc/lloguser.cpp" 
    #STATIC "oflog/libsrc/logevent.cpp" 
    #STATIC "oflog/libsrc/logger.cpp" 
    #STATIC "oflog/libsrc/logimpl.cpp" 
    #STATIC "oflog/libsrc/loglevel.cpp" 
    #STATIC "oflog/libsrc/loglog.cpp" 
    #STATIC "oflog/libsrc/ndc.cpp" 
    #STATIC "oflog/libsrc/ntelogap.cpp" 
    #STATIC "oflog/libsrc/nullap.cpp" 
    #STATIC "oflog/libsrc/objreg.cpp" 
    #STATIC "oflog/libsrc/oflog.cpp" 
    #STATIC "oflog/libsrc/patlay.cpp" 
    #STATIC "oflog/libsrc/pointer.cpp" 
    #STATIC "oflog/libsrc/property.cpp" 
    #STATIC "oflog/libsrc/rootlog.cpp" 
    #STATIC "oflog/libsrc/sleep.cpp" 
    #STATIC "oflog/libsrc/sockbuff.cpp" 
    #STATIC "oflog/libsrc/socket.cpp" 
    #STATIC "oflog/libsrc/socketap.cpp" 
    #STATIC "oflog/libsrc/strhelp.cpp" 
    #STATIC "oflog/libsrc/syncprims.cpp" 
    #STATIC "oflog/libsrc/syslogap.cpp" 
    #STATIC "oflog/libsrc/threads.cpp" 
    #STATIC "oflog/libsrc/timehelp.cpp" 
    #STATIC "oflog/libsrc/winconap.cpp" 
    #STATIC "oflog/libsrc/windebap.cpp" 
    ##STATIC "oflog/libsrc/winsock.cpp" 
    #STATIC "ofstd/libsrc/ofcmdln.cpp" 
    #STATIC "ofstd/libsrc/ofconapp.cpp" 
    #STATIC "ofstd/libsrc/ofcond.cpp" 
    #STATIC "ofstd/libsrc/ofconfig.cpp" 
    #STATIC "ofstd/libsrc/ofconsol.cpp" 
    #STATIC "ofstd/libsrc/ofcrc32.cpp" 
    #STATIC "ofstd/libsrc/ofdate.cpp" 
    #STATIC "ofstd/libsrc/ofdatime.cpp" 
    #STATIC "ofstd/libsrc/offname.cpp" 
    #STATIC "ofstd/libsrc/oflist.cpp" 
    #STATIC "ofstd/libsrc/ofstd.cpp" 
    #STATIC "ofstd/libsrc/ofstring.cpp" 
    #STATIC "ofstd/libsrc/ofthread.cpp" 
    #STATIC "ofstd/libsrc/oftime.cpp" 
#)


    
target_link_libraries(dcmtk-3.6.0 ijg8 ijg12 ijg16)