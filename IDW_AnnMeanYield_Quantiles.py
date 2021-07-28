from qgis import processing

metric = "ann_mean_yield"

version = "2021-05"

inshp = "C:/Users/noteboomm/Documents/CESI/00_Shapefiles/RHBN_U_pts_"+metric+"_Hydat_"+version+".shp"
outstring = "C:/Users/noteboomm/Documents/CESI/Rasters/"+metric

for attrib in range(27,46):
    year = int(attrib + 1974)
    #attrib = attrib - 1
    
    print("'INTERPOLATION_DATA':'"+inshp+"::~::0::~::"+str(attrib)+"::~::0'")
    print("'OUTPUT':'"+outstring+str(year)+"_Hydat_"+version+"_RHBN-U_IDW5_10k.tif'")

    processing.run("qgis:idwinterpolation",
                   {'INTERPOLATION_DATA':inshp+'::~::0::~::'+str(attrib)+'::~::0',
                   'DISTANCE_COEFFICIENT':5,
                   'EXTENT':'-2313851.626876211,3003894.9530195706,-675872.3326588598,2666752.7970590233 [EPSG:3978]',
                   'PIXEL_SIZE':10000,
                   'OUTPUT':outstring+'_'+str(year)+'_Hydat_'+version+'_RHBN-U_IDW5_10k.tif'})
                   
    processing.run("gdal:cliprasterbymasklayer", 
                   {'INPUT':outstring+'_'+str(year)+'_Hydat_'+version+'_RHBN-U_IDW5_10k.tif',
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
                    'OUTPUT':outstring+'_'+str(year)+'_Hydat_'+version+'_RHBN-U_IDW5_10k_clip.tif'})
    
    os.remove('C:/Users/noteboomm/Documents/CESI/Rasters/_temp.tif')
