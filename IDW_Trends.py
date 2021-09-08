from qgis import processing

"""
Important note: QGIS version 3.16.7 seems to execute the IDW algorithm differently
from QGIS version v3.10.2. The newer version seems to force the output surface towards
zero even if surrounded by non-zero points, which leads to spurious 'red' patches in 
the Arctic and parts of northern Ontario and the Prairies.

This routine has been tested and run on version 3.10.2 for CESI-WQ to be released 
early 2022. Anyone working on future updates/releases - pay attention to raster 
outputs as compared to sample points.
"""

#metrics = ["ann_mean_yield","pot_days","pot_events","pot_max_dur", "pot_mean_dur",
#           "X1_day_max", "dr_days","dut_max_dur","X7_day_min"]

print("Routine to run inverse distance weighted (IDW) interpolation\n on trend data")

metrics = [ "ann_mean_yield"] #"pot_days",

version = "2021-07"

for metric in metrics:
    inshp = "C:/Users/noteboomm/Documents/CESI/00_Shapefiles/RHBN_U_pts_"+metric+"_trend_Hydat_"+version+".shp"
    outstring = "C:/Users/noteboomm/Documents/CESI/Rasters/"+metric
    
    attrib = "9"
    print("'INTERPOLATION_DATA':'"+inshp+"::~::0::~::"+str(attrib)+"::~::0'")
    print("'OUTPUT':'"+outstring+"_trend_Hydat_"+version+"_RHBN-U_IDW5_10k.tif'")

    processing.run("qgis:idwinterpolation",
                   {'INTERPOLATION_DATA':inshp+'::~::0::~::'+str(attrib)+'::~::0',
                   'DISTANCE_COEFFICIENT':5,
                   'EXTENT':'-2313851.626876211,3003894.9530195706,-675872.3326588598,2666752.7970590233 [EPSG:3978]',
                   'PIXEL_SIZE':10000,
                   'OUTPUT':outstring+'_trend_Hydat_'+version+'_RHBN-U_IDW5_10k.tif'})
    
    processing.run("gdal:cliprasterbymasklayer", 
                   {'INPUT':outstring+'_trend_Hydat_'+version+'_RHBN-U_IDW5_10k.tif',
                    'MASK':'C:/Users/noteboomm/Documents/Canada_Reference/CanadaBound.shp',
                    'SOURCE_CRS':None,'TARGET_CRS':None,'NODATA':None,'ALPHA_BAND':False,
                    'CROP_TO_CUTLINE':True,'KEEP_RESOLUTION':True,'SET_RESOLUTION':False,'X_RESOLUTION':None,
                    'Y_RESOLUTION':None,'MULTITHREADING':False,'OPTIONS':'','DATA_TYPE':0,'EXTRA':'',
                    'OUTPUT':'C:/Users/noteboomm/Documents/CESI/Rasters/_temp.tif'})
                       
    processing.run("gdal:cliprasterbymasklayer", 
                   {'INPUT':'C:/Users/noteboomm/Documents/CESI/Rasters/_temp.tif',
                    'MASK':'C:/Users/noteboomm/Documents/Canada_Reference/CanadaBound_noQEIslands.shp',
                    'SOURCE_CRS':None,'TARGET_CRS':None,'NODATA':None,'ALPHA_BAND':False,
                    'CROP_TO_CUTLINE':False,'KEEP_RESOLUTION':True,'SET_RESOLUTION':False,'X_RESOLUTION':None,
                    'Y_RESOLUTION':None,'MULTITHREADING':False,'OPTIONS':'','DATA_TYPE':0,'EXTRA':'',
                    'OUTPUT':outstring+'_trend_Hydat_'+version+'_RHBN-U_IDW5_10k_clip.tif'})
    
    os.remove('C:/Users/noteboomm/Documents/CESI/Rasters/_temp.tif')

    print("'OUTPUT':'"+outstring+"_trend_Hydat_"+version+"_RHBN-U_IDW5_10k.tif'\n interpolation and clipping complete\n")
