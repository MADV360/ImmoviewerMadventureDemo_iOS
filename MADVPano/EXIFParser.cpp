//
//  EXIFParser.c
//  Madv360_v1
//
//  Created by QiuDong on 2017/1/17.
//  Copyright © 2017年 Cyllenge. All rights reserved.
//

#include "EXIFParser.h"
#include "exiv2/include/exiv2.hpp"
#include "Log.h"
#include <stdlib.h>

//#ifndef TARGET_OS_ANDROID
#include <string>
#include <string.h>
#include <stdio.h>
#include <iomanip>
#include <cassert>
#include <cmath>
#include <sstream>

/* https://www.adobe.com/content/dam/Adobe/en/devnet/xmp/pdfs/XMPSpecificationPart1.pdf
 8.2.1.2 Date
 A date-time value, which is represented using a subset of Date and Time Formats formatting:
 YYYY
 YYYY-MM
 YYYY-MM-DD
 YYYY-MM-DDThh:mmTZD
 YYYY-MM-DDThh:mm:ssTZD
 YYYY-MM-DDThh:mm:ss.sTZD
 In which:
 • YYYY = four-digit year
 • MM = two-digit month (01=January)
 • DD = two-digit day of month (01 through 31)
 • hh = two digits of hour (00 through 23)
 • mm = two digits of minute (00 through 59)
 • ss = two digits of second (00 through 59)
 • s = one or more digits representing a decimal fraction of a second
 • TZD = time zone designator (Z or +hh:mm or -hh:mm)
 The time zone designator need not be present in XMP. When not present, the time zone is unknown, and an
 XMP processor should not assume anything about the missing time zone.
 Local time-zone designators +hh:mm or -hh:mm should be used when possible instead of converting to UTC.
 ©Adobe Systems Incorporated, 2010 29
 NOTE If a file was saved at noon on October 23, a timestamp of 2004-10-23T12:00:00-06:00 conveys more
 information than 2004-10-23T18:00:00Z.
 */

bool setXmpGPanoPacket(const char* imagePath) {
    if (NULL == imagePath) {
        return false;
    }

    long imageHandler = createExivImage(imagePath);
    copyEXIFDataFromExivImage(imagePath, imageHandler);
    releaseExivImage(imageHandler);

    return true;
}

int exifPrint(const char* imagePath, std::ostream& output) {
    try
    {
        if (NULL == imagePath)
        {
            output << "No file path.\n";
            return 1;
        }
        Exiv2::Image::AutoPtr image = Exiv2::ImageFactory::open(imagePath);
        assert(image.get() != 0);
        image->readMetadata();
        Exiv2::ExifData &exifData = image->exifData();
        if (exifData.empty())
        {
            std::string error(imagePath);
            error += ": No Exif data found in the file";
            throw Exiv2::Error(1, error);
        }
        Exiv2::ExifData::const_iterator end = exifData.end();
        for (Exiv2::ExifData::const_iterator i = exifData.begin(); i != end; ++i)
        {
            const char* tn = i->typeName();
            output << std::setw(44) << std::setfill(' ') << std::left
            << i->key() << " "
            << "0x" << std::setw(4) << std::setfill('0') << std::right
            << std::hex << i->tag() << " "
            << std::setw(9) << std::setfill(' ') << std::left
            << (tn ? tn : "Unknown") << " "
            << std::dec << std::setw(3)
            << std::setfill(' ') << std::right
            << i->count() << "  "
            << std::dec << i->value()
            << "\n";
        }
        
        output << "XMP packet:\n" << image->xmpPacket() << std::endl;
        return 0;
    }
    //catch (std::exception& e) {
    //catch (Exiv2::AnyError& e) {
    catch (Exiv2::Error& e)
    {
        output << "Caught Exiv2 exception '" << e.what() << "'\n";
        return -1;
    }
}

int exifAddModDel(const char* imagePath) {
    try
    {
        if (NULL == imagePath)
        {
            std::cout << "No file path.\n";
            return 1;
        }
        std::string file(imagePath);
        // Container for exif metadata. This is an example of creating
        // exif metadata from scratch. If you want to add, modify, delete
        // metadata that exists in an image, start with ImageFactory::open
        Exiv2::ExifData exifData;
        // *************************************************************************
        // Add to the Exif data
        // This is the quickest way to add (simple) Exif data. If a metadatum for
        // a given key already exists, its value is overwritten. Otherwise a new
        // tag is added.
        exifData["Exif.Image.Model"] = "Test 1";                     // AsciiValue
        exifData["Exif.Image.SamplesPerPixel"] = uint16_t(162);      // UShortValue
        exifData["Exif.Image.XResolution"] = int32_t(-2);            // LongValue
        exifData["Exif.Image.YResolution"] = Exiv2::Rational(-2, 3); // RationalValue
        std::cout << "Added a few tags the quick way.\n";
        // Create a ASCII string value (note the use of create)
        Exiv2::Value::AutoPtr v = Exiv2::Value::create(Exiv2::asciiString);
        // Set the value to a string
        v->read("1999:12:31 23:59:59");
        // Add the value together with its key to the Exif data container
        Exiv2::ExifKey key("Exif.Photo.DateTimeOriginal");
        exifData.add(key, v.get());
        std::cout << "Added key \"" << key << "\", value \"" << *v << "\"\n";
        // Now create a more interesting value (without using the create method)
        Exiv2::URationalValue::AutoPtr rv(new Exiv2::URationalValue);
        // Set two rational components from a string
        rv->read("1/2 1/3");
        // Add more elements through the extended interface of rational value
        rv->value_.push_back(std::make_pair(2,3));
        rv->value_.push_back(std::make_pair(3,4));
        // Add the key and value pair to the Exif data
        key = Exiv2::ExifKey("Exif.Image.PrimaryChromaticities");
        exifData.add(key, rv.get());
        std::cout << "Added key \"" << key << "\", value \"" << *rv << "\"\n";
        // *************************************************************************
        // Modify Exif data
        // Since we know that the metadatum exists (or we don't mind creating a new
        // tag if it doesn't), we can simply do this:
        Exiv2::Exifdatum& tag = exifData["Exif.Photo.DateTimeOriginal"];
        std::string date = tag.toString();
        date.replace(0, 4, "2000");
        tag.setValue(date);
        std::cout << "Modified key \"" << tag.key()
        << "\", new value \"" << tag.value() << "\"\n";
        // Alternatively, we can use findKey()
        key = Exiv2::ExifKey("Exif.Image.PrimaryChromaticities");
        Exiv2::ExifData::iterator pos = exifData.findKey(key);
        if (pos == exifData.end()) throw Exiv2::Error(1, "Key not found");
        // Get a pointer to a copy of the value
        v = pos->getValue();
        // Downcast the Value pointer to its actual type
        Exiv2::URationalValue* prv = dynamic_cast<Exiv2::URationalValue*>(v.release());
        if (prv == 0) throw Exiv2::Error(1, "Downcast failed");
        rv = Exiv2::URationalValue::AutoPtr(prv);
        // Modify the value directly through the interface of URationalValue
        rv->value_[2] = std::make_pair(88,77);
        // Copy the modified value back to the metadatum
        pos->setValue(rv.get());
        std::cout << "Modified key \"" << key
        << "\", new value \"" << pos->value() << "\"\n";
        // *************************************************************************
        // Delete metadata from the Exif data container
        // Delete the metadatum at iterator position pos
        key = Exiv2::ExifKey("Exif.Image.PrimaryChromaticities");
        pos = exifData.findKey(key);
        if (pos == exifData.end()) throw Exiv2::Error(1, "Key not found");
        exifData.erase(pos);
        std::cout << "Deleted key \"" << key << "\"\n";
        // *************************************************************************
        // Finally, write the remaining Exif data to the image file
        Exiv2::Image::AutoPtr image = Exiv2::ImageFactory::open(file);
        assert(image.get() != 0);
        image->setExifData(exifData);
        image->writeMetadata();
        return 0;
    }
    catch (Exiv2::AnyError& e)
    {
        std::cout << "Caught Exiv2 exception '" << e << "'\n";
        return -1;
    }
}

void copyEXIFData(const char* destImagePath, const char* sourceImagePath) {
    Exiv2::Image::AutoPtr sourceImage = Exiv2::ImageFactory::open(sourceImagePath);
    assert(sourceImage.get() != 0);
    sourceImage->readMetadata();
    Exiv2::ExifData &exifData = sourceImage->exifData();
    if (exifData.empty())
    {
//        std::string error(sourceImagePath);
//        error += ": No Exif data found in sourceImage";
//        throw Exiv2::Error(1, error);
        return;
    }
    
    Exiv2::ExifKey key("Exif.Photo.SceneType");
    Exiv2::ExifData::iterator pos = exifData.findKey(key);
    if (pos != exifData.end())
    {
        Exiv2::ValueType<uint32_t> newValue(Exiv2::unsignedLong);
        newValue.read("0");
        pos->setValue(&newValue);
    }
    
    Exiv2::Image::AutoPtr destImage = Exiv2::ImageFactory::open(destImagePath);
    assert(destImage.get() != 0);
    destImage->setExifData(exifData);
    destImage->writeMetadata();
}

void setEXIFFileSource(const char* destImagePath, const char* sourceImagePath) {
    Exiv2::Image::AutoPtr sourceImage = Exiv2::ImageFactory::open(sourceImagePath);
    assert(sourceImage.get() != 0);
    sourceImage->readMetadata();
    Exiv2::ExifData &exifData = sourceImage->exifData();
    if (exifData.empty())
    {
        //        std::string error(sourceImagePath);
        //        error += ": No Exif data found in sourceImage";
        //        throw Exiv2::Error(1, error);
        return;
    }
    
    Exiv2::ExifKey key("Exif.Photo.FileSource");
    Exiv2::ExifData::iterator pos = exifData.findKey(key);
    Exiv2::ValueType<uint32_t> newValue(Exiv2::unsignedLong);
    newValue.read("1493172224");
    if (pos != exifData.end())
    {
        pos->setValue(&newValue);
    }
    else
    {
        exifData.add(key, &newValue);
    }
    
    Exiv2::Image::AutoPtr destImage = Exiv2::ImageFactory::open(destImagePath);
    assert(destImage.get() != 0);
    destImage->setExifData(exifData);
    destImage->writeMetadata();
}

class Exiv2ImageWrapper {
public:
    ~Exiv2ImageWrapper();
    
    Exiv2ImageWrapper(Exiv2::Image::AutoPtr image);
    
    Exiv2::Image::AutoPtr _image;
};

Exiv2ImageWrapper::~Exiv2ImageWrapper() {
    _image.release();
}

Exiv2ImageWrapper::Exiv2ImageWrapper(Exiv2::Image::AutoPtr image)
: _image(image)
{
}

long createExivImage(const char* sourceImagePath) {
    Exiv2::Image::AutoPtr sourceImage = Exiv2::ImageFactory::open(sourceImagePath);
    assert(sourceImage.get() != 0);
    sourceImage->readMetadata();
    Exiv2ImageWrapper* wrapper = new Exiv2ImageWrapper(sourceImage);
    return (long)wrapper;
}

void releaseExivImage(long exivImageHandler) {
    Exiv2ImageWrapper* wrapper = (Exiv2ImageWrapper*) exivImageHandler;
    delete wrapper;
}

void exivImageEraseGyroData(long exivImageHandler) {
    if (0 == exivImageHandler)
        return;
    
    Exiv2ImageWrapper* wrapper = (Exiv2ImageWrapper*) exivImageHandler;
    Exiv2::ExifData &exifData = wrapper->_image->exifData();
    
    Exiv2::ExifKey key("Exif.Photo.UserComment");
    Exiv2::ExifData::iterator pos = exifData.findKey(key);
    if (pos != exifData.end())
    {
        exifData.erase(pos);
    }
    
    //sourceImage->writeMetadata();
}

void exivImageEraseSceneType(long exivImageHandler) {
    if (0 == exivImageHandler)
        return;
    
    Exiv2ImageWrapper* wrapper = (Exiv2ImageWrapper*) exivImageHandler;
    Exiv2::ExifData &exifData = wrapper->_image->exifData();
    
    Exiv2::ExifKey key("Exif.Photo.SceneType");
    Exiv2::ExifData::iterator pos = exifData.findKey(key);
    if (pos != exifData.end())
    {
        Exiv2::ValueType<uint32_t> newValue(Exiv2::unsignedLong);
        newValue.read("0");
        pos->setValue(&newValue);
    }
    
    //sourceImage->writeMetadata();
}

void exivImageEraseFileSource(long exivImageHandler) {
    if (0 == exivImageHandler)
        return;
    
    Exiv2ImageWrapper* wrapper = (Exiv2ImageWrapper*) exivImageHandler;
    Exiv2::ExifData &exifData = wrapper->_image->exifData();
    
    Exiv2::ExifKey key("Exif.Photo.FileSource");
    Exiv2::ExifData::iterator pos = exifData.findKey(key);
    if (pos != exifData.end())
    {
        Exiv2::ValueType<uint32_t> newValue(Exiv2::unsignedLong);
        newValue.read("0");
        pos->setValue(&newValue);
    }
    
    //sourceImage->writeMetadata();
}

void exivImageSaveMetaData(long exivImageHandler) {
    if (0 == exivImageHandler)
        return;
    
    Exiv2ImageWrapper* wrapper = (Exiv2ImageWrapper*) exivImageHandler;
    wrapper->_image->writeMetadata();
}

void copyEXIFDataFromExivImage(const char* destImagePath, long sourceExivImageHandler) {
    if (0 == sourceExivImageHandler || NULL == destImagePath)
        return;
    
    Exiv2ImageWrapper* wrapper = (Exiv2ImageWrapper*) sourceExivImageHandler;
    
    Exiv2::Image::AutoPtr destImage = Exiv2::ImageFactory::open(destImagePath);
    assert(destImage.get() != 0);
    
    std::string maker("MADV");
    std::string model("MJXJ");
    std::string fwVer("1.3.97.85.5.13333");
    Exiv2::ExifData &exifData = wrapper->_image->exifData();
    if (!exifData.empty())
    {
//        std::string error("");
//        error += ": No Exif data found in sourceImage";
//        throw Exiv2::Error(1, error);
//        Exiv2::ExifKey key("Exif.Photo.SceneType");
//        Exiv2::ExifData::iterator pos = exifData.findKey(key);
//        if (pos != exifData.end())
//        {
//            Exiv2::ValueType<uint32_t> newValue(Exiv2::unsignedLong);
//            newValue.read("0");
//            pos->setValue(&newValue);
//        }

        Exiv2::ExifThumb exifThumb(exifData);
        exifThumb.erase();
        destImage->setExifData(exifData);
        
        Exiv2::ExifKey makerKey(ExifKeyMaker);
        Exiv2::ExifData::iterator found = exifData.findKey(makerKey);
        if (found != exifData.end())
        {
            maker = found->getValue()->toString();
        }
        
        Exiv2::ExifKey modelKey(ExifKeyDeviceModel);
        found = exifData.findKey(modelKey);
        if (found != exifData.end())
        {
            model = found->getValue()->toString();
        }
        
        Exiv2::ExifKey fwVerKey(ExifKeySoftware);
        found = exifData.findKey(fwVerKey);
        if (found != exifData.end())
        {
            fwVer = found->getValue()->toString();
            int lastIndexOfSemicolon = fwVer.find_last_of(";");
            if (lastIndexOfSemicolon != std::string::npos && lastIndexOfSemicolon < fwVer.length()-1)
            {
                fwVer = fwVer.substr(lastIndexOfSemicolon + 1);
            }
        }
    }
    
    std::ostringstream ossXmpPacket;
    ossXmpPacket << "<?xpacket begin='?' id='W5M0MpCehiHzreSzNTczkc9d'?> \n"
    "<x:xmpmeta xmlns:x='adobe:ns:meta/' x:xmptk='XMP Core 5.4.0'> \n"
    "    <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'> \n"
    "        <rdf:Description rdf:about='' xmlns:GPano='http://ns.google.com/photos/1.0/panorama/' \n"
    "         xmlns:xmp='http://ns.adobe.com/xap/1.0/' xmp:CreatorTool='"
    << maker << " " << model << " Ver " << fwVer << "'> \n"
    "         <GPano:UsePanoramaViewer>True</GPano:UsePanoramaViewer>\n"
    "         <GPano:CaptureSoftware>MADV360</GPano:CaptureSoftware>\n"
    "         <GPano:StitchingSoftware>MADV360</GPano:StitchingSoftware>\n"
    "         <GPano:ProjectionType>equirectangular</GPano:ProjectionType>\n"
    "         <GPano:PoseHeadingDegrees>350.0</GPano:PoseHeadingDegrees>\n"
    "         <GPano:InitialViewHeadingDegrees>90.0</GPano:InitialViewHeadingDegrees>\n"
    "         <GPano:InitialViewPitchDegrees>0.0</GPano:InitialViewPitchDegrees>\n"
    "         <GPano:InitialViewRollDegrees>0.0</GPano:InitialViewRollDegrees>\n"
    "         <GPano:InitialHorizontalFOVDegrees>75.0</GPano:InitialHorizontalFOVDegrees>\n"
    "         <GPano:CroppedAreaLeftPixels>0</GPano:CroppedAreaLeftPixels>\n"
    "         <GPano:CroppedAreaTopPixels>0</GPano:CroppedAreaTopPixels>\n";
    
    std::string widthString, heightString;
    int width = wrapper->_image->pixelWidth();
    int height = wrapper->_image->pixelHeight();
    if (width > 0 && height > 0)
    {
        char cstrWidthHeight[8];
        sprintf(cstrWidthHeight, "%d", width);
        widthString = cstrWidthHeight;
        sprintf(cstrWidthHeight, "%d", height);
        heightString = cstrWidthHeight;
    }
    else
    {
        widthString = "6912";
        heightString = "3456";
    }
    
    if (!exifData.empty())
    {
        std::string dateString;
        Exiv2::ExifData::iterator pos = exifData.findKey(Exiv2::ExifKey("Exif.Photo.DateTimeOriginal"));
        if (pos != exifData.end())
        {
            Exiv2::Value::AutoPtr v = pos->getValue();
            dateString = v->toString();
        }
//        else
//        {
//            pos = exifData.findKey(Exiv2::ExifKey("Exif.Photo.DateTime"));
//            if (pos != exifData.end())
//            {
//                Exiv2::Value::AutoPtr v = pos->getValue();
//                dateString = v->toString();
//            }
//        }
//#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
//        if (dateString.length() > 0)
//        {
//            // EXIF date: 2017:07:15 15:56:40
//            NSDateFormatter* exifDateFormatter = [[NSDateFormatter alloc] init];
//            exifDateFormatter.dateFormat = @"yyyy:MM:dd HH:mm:ss";
//            NSDate* date = [exifDateFormatter dateFromString:[NSString stringWithUTF8String:dateString.c_str()]];
//            
//            // Ref: https://stackoverflow.com/questions/14592556/objective-c-how-can-i-get-the-current-date-in-utc-timezone
//            NSTimeZone* timeZone = [NSTimeZone defaultTimeZone];
//            // or Timezone with specific name like
//            // [NSTimeZone timeZoneWithName:@"Europe/Riga"] (see link below)
//            NSDateFormatter* xmpDateFormatter = [[NSDateFormatter alloc] init];
//            [xmpDateFormatter setTimeZone:timeZone];
//            [xmpDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
//            dateString = [xmpDateFormatter stringFromDate:date].UTF8String;
//        }
//        ossXmpPacket << "         <GPano:FirstPhotoDate>" << dateString << "</GPano:FirstPhotoDate>\n";
//        ossXmpPacket << "         <GPano:LastPhotoDate>" << dateString << "</GPano:LastPhotoDate>\n";
//#endif
        
        pos = exifData.findKey(Exiv2::ExifKey("Exif.Photo.PixelXDimension"));
        if (pos != exifData.end())
        {
            widthString = pos->getValue()->toString();
        }
        pos = exifData.findKey(Exiv2::ExifKey("Exif.Photo.PixelYDimension"));
        if (pos != exifData.end())
        {
            heightString = pos->getValue()->toString();
        }
    }
    
    ossXmpPacket << "         <GPano:CroppedAreaImageWidthPixels>" << widthString << "</GPano:CroppedAreaImageWidthPixels>\n";
    ossXmpPacket << "         <GPano:FullPanoWidthPixels>" << widthString << "</GPano:FullPanoWidthPixels>\n";
    ossXmpPacket << "         <GPano:CroppedAreaImageHeightPixels>" << heightString << "</GPano:CroppedAreaImageHeightPixels>\n";
    ossXmpPacket << "         <GPano:FullPanoHeightPixels>" << heightString << "</GPano:FullPanoHeightPixels>\n";
    ossXmpPacket << "         <GPano:SourcePhotosCount>2</GPano:SourcePhotosCount>\n"
    "         <GPano:ExposureLockUsed>False</GPano:ExposureLockUsed>\n"
    "        </rdf:Description> \n"
    "    </rdf:RDF> \n"
    "</x:xmpmeta> \n"
    "<?xpacket end='w'?>  \n";
    
    destImage->setXmpPacket(ossXmpPacket.str());
    
    destImage->writeMetadata();
}

int exifComment(const char* imagePath) {
    try
    {
        if (NULL == imagePath)
        {
            std::cout << "No file path.\n";
            return 1;
        }
        Exiv2::Image::AutoPtr image = Exiv2::ImageFactory::open(imagePath);
        assert (image.get() != 0);
        image->readMetadata();
        Exiv2::ExifData &exifData = image->exifData();
        /*
         Exiv2 uses a CommentValue for Exif user comments. The format of the
         comment string includes an optional charset specification at the beginning:
         [charset=["]Ascii|Jis|Unicode|Undefined["] ]comment
         Undefined is used as a default if the comment doesn't start with a charset
         definition.
         Following are a few examples of valid comments. The last one is written to
         the file.
         */
        exifData["Exif.Photo.UserComment"]
        = "charset=\"Unicode\" An Unicode Exif comment added with Exiv2";
        exifData["Exif.Photo.UserComment"]
        = "charset=\"Undefined\" An undefined Exif comment added with Exiv2";
        exifData["Exif.Photo.UserComment"]
        = "Another undefined Exif comment added with Exiv2";
        exifData["Exif.Photo.UserComment"]
        = "charset=Ascii An ASCII Exif comment added with Exiv2";
        std::cout << "Writing user comment '"
        << exifData["Exif.Photo.UserComment"]
        << "' back to the image\n";
        image->writeMetadata();
        return 0;
    }
    catch (Exiv2::AnyError& e)
    {
        std::cout << "Caught Exiv2 exception '" << e << "'\n";
        return -1;
    }
}

int iptcPrint(const char* imagePath) {
    try
    {
        if (NULL == imagePath)
        {
            std::cout << "No file path.\n";
            return 1;
        }
        Exiv2::Image::AutoPtr image = Exiv2::ImageFactory::open(imagePath);
        assert (image.get() != 0);
        image->readMetadata();
        Exiv2::IptcData &iptcData = image->iptcData();
        if (iptcData.empty())
        {
            std::string error(imagePath);
            error += ": No IPTC data found in the file";
            throw Exiv2::Error(1, error);
        }
        Exiv2::IptcData::iterator end = iptcData.end();
        for (Exiv2::IptcData::iterator md = iptcData.begin(); md != end; ++md)
        {
            std::cout << std::setw(44) << std::setfill(' ') << std::left
            << md->key() << " "
            << "0x" << std::setw(4) << std::setfill('0') << std::right
            << std::hex << md->tag() << " "
            << std::setw(9) << std::setfill(' ') << std::left
            << md->typeName() << " "
            << std::dec << std::setw(3)
            << std::setfill(' ') << std::right
            << md->count() << "  "
            << std::dec << md->value()
            << std::endl;
        }
        return 0;
    }
    catch (Exiv2::AnyError& e)
    {
        std::cout << "Caught Exiv2 exception '" << e << "'\n";
        return -1;
    }
}

int iptcEasy(const char* imagePath) {
    try
    {
        if (NULL == imagePath)
        {
            std::cout << "No file path.\n";
            return 1;
        }
        std::string file(imagePath);
        Exiv2::IptcData iptcData;
        iptcData["Iptc.Application2.Headline"] = "The headline I am";
        iptcData["Iptc.Application2.Keywords"] = "Yet another keyword";
        iptcData["Iptc.Application2.DateCreated"] = "2004-8-3";
        iptcData["Iptc.Application2.Urgency"] = uint16_t(1);
        iptcData["Iptc.Envelope.ModelVersion"] = 42;
        iptcData["Iptc.Envelope.TimeSent"] = "14:41:0-05:00";
        iptcData["Iptc.Application2.RasterizedCaption"] = "230 42 34 2 90 84 23 146";
        iptcData["Iptc.0x0009.0x0001"] = "Who am I?";
        Exiv2::StringValue value;
        value.read("very!");
        iptcData["Iptc.Application2.Urgency"] = value;
        std::cout << "Time sent: " << iptcData["Iptc.Envelope.TimeSent"] << "\n";
        // Open image file
        Exiv2::Image::AutoPtr image = Exiv2::ImageFactory::open(file);
        assert (image.get() != 0);
        // Set IPTC data and write it to the file
        image->setIptcData(iptcData);
        image->writeMetadata();
        return 0;
    }
    catch (Exiv2::AnyError& e)
    {
        std::cout << "Caught Exiv2 exception '" << e << "'\n";
        return -1;
    }
}

//#endif //#ifndef TARGET_OS_ANDROID

int int16FromBytes(const uint8_t* bytes, bool isBigEndian) {
    if (isBigEndian)
    {
        return (bytes[0] << 8) | bytes[1];
    }
    else
    {
        return (bytes[1] << 8) | bytes[0];
    }
}

void int16Bytes(uint8_t* bytes, int16_t value, bool isBigEndian) {
    if (isBigEndian)
    {
        bytes[0] = (value >> 8) & 0xff;
        bytes[1] = (value >> 0) & 0xff;
    }
    else
    {
        bytes[1] = (value >> 8) & 0xff;
        bytes[0] = (value >> 0) & 0xff;
    }
}

int int32FromBytes(const uint8_t* bytes, bool isBigEndian) {
    if (isBigEndian)
    {
        return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | (bytes[3] << 0);
    }
    else
    {
        return (bytes[3] << 24) | (bytes[2] << 16) | (bytes[1] << 8) | (bytes[0] << 0);
    }
}

void int32Bytes(uint8_t* bytes, int32_t value, bool isBigEndian) {
    if (isBigEndian)
    {
        bytes[0] = (value >> 24) & 0xff;
        bytes[1] = (value >> 16) & 0xff;
        bytes[2] = (value >> 8) & 0xff;
        bytes[3] = (value >> 0) & 0xff;
    }
    else
    {
        bytes[3] = (value >> 24) & 0xff;
        bytes[2] = (value >> 16) & 0xff;
        bytes[1] = (value >> 8) & 0xff;
        bytes[0] = (value >> 0) & 0xff;
    }
}

int64_t int64FromBytes(const uint8_t* bytes, bool isBigEndian) {
    if (isBigEndian)
    {
        return (((int64_t)bytes[0]) << 56) | (((int64_t)bytes[1]) << 48) | (((int64_t)bytes[2]) << 40) | (((int64_t)bytes[3]) << 32 | bytes[4] << 24) | (bytes[5] << 16) | (bytes[6] << 8) | (bytes[7] << 0);
    }
    else
    {
        return (((int64_t)bytes[7]) << 56) | (((int64_t)bytes[6]) << 48) | (((int64_t)bytes[5]) << 40) | (((int64_t)bytes[4]) << 32) | (bytes[3] << 24) | (bytes[2] << 16) | (bytes[1] << 8) | (bytes[0] << 0);
    }
}

void int64Bytes(uint8_t* bytes, int64_t value, bool isBigEndian) {
    if (isBigEndian)
    {
        bytes[0] = (value >> 56) & 0xff;
        bytes[1] = (value >> 48) & 0xff;
        bytes[2] = (value >> 40) & 0xff;
        bytes[3] = (value >> 32) & 0xff;
        bytes[4] = (value >> 24) & 0xff;
        bytes[5] = (value >> 16) & 0xff;
        bytes[6] = (value >> 8) & 0xff;
        bytes[7] = (value >> 0) & 0xff;
    }
    else
    {
        bytes[7] = (value >> 56) & 0xff;
        bytes[6] = (value >> 48) & 0xff;
        bytes[5] = (value >> 40) & 0xff;
        bytes[4] = (value >> 32) & 0xff;
        bytes[3] = (value >> 24) & 0xff;
        bytes[2] = (value >> 16) & 0xff;
        bytes[1] = (value >> 8) & 0xff;
        bytes[0] = (value >> 0) & 0xff;
    }
}

uint16_t sizeOfDEValueType(DEValueType type) {
    switch (type)
    {
        case DEByte:
        case DEString:
        case DESByte:
        case DEUndefined:
            return 1;
        case DEShort:
        case DESShort:
            return 2;
        case DELong:
        case DESLong:
        case DEFloat:
            return 4;
        case DEDouble:
        case DERational:
        case DESRational:
            return 8;
    }
}

void printDescriptionOfDEValue(std::ostringstream& stringStream, void* ptrValue, DEValueType type, bool isBigEndian) {
    switch (type)
    {
        case DEByte:
        {
            uint8_t* ptrByteValue = (uint8_t*) ptrValue;
            stringStream << std::hex << (*ptrByteValue);
        }
            break;
        case DEString:
        {
            unsigned char* str = (unsigned char*) ptrValue;
            stringStream << str;
        }
            break;
        case DESByte:
        {
            int8_t* ptrSByteValue = (int8_t*) ptrValue;
            stringStream << (*ptrSByteValue);
        }
            break;
        case DEUndefined:
        {
            uint8_t* ptrUByteValue = (uint8_t*) ptrValue;
            stringStream << std::hex << (*ptrUByteValue);
        }
            break;
        case DEShort:
        {
            uint16_t shortValue = (uint16_t) int16FromBytes((uint8_t*)ptrValue, isBigEndian);
            stringStream << shortValue;
        }
            break;
        case DESShort:
        {
            int16_t sshortValue = (int16_t) int16FromBytes((uint8_t*)ptrValue, isBigEndian);
            stringStream << sshortValue;
        }
            break;
        case DELong:
        {
            uint32_t longValue = (uint32_t) int32FromBytes((uint8_t*)ptrValue, isBigEndian);
            stringStream << longValue;
        }
            break;
        case DESLong:
        {
            int32_t slongValue = (int32_t) int32FromBytes((uint8_t*)ptrValue, isBigEndian);
            stringStream << slongValue;
        }
            break;
        case DEFloat:
        {
            uint32_t iFloatValue = (uint32_t) int32FromBytes((uint8_t*)ptrValue, isBigEndian);
            float* ptrFloatValue = (float*)&iFloatValue;
            stringStream << (*ptrFloatValue);
        }
            break;
        case DEDouble:
        {
            int64_t lDoubleValue = (int64_t) int64FromBytes((uint8_t*)ptrValue, isBigEndian);
            double* ptrDoubleValue = (double*)&lDoubleValue;
            stringStream << (*ptrDoubleValue);
        }
            break;
        case DERational:
        {
            uint32_t numeratorValue = (uint32_t) int32FromBytes((uint8_t*)ptrValue, isBigEndian);
            uint32_t denominatorValue = (uint32_t) int32FromBytes(((uint8_t*)ptrValue) + 4, isBigEndian);
            stringStream << numeratorValue << "/" << denominatorValue;
        }
            break;
        case DESRational:
        {
            int32_t sNumeratorValue = (uint32_t) int32FromBytes((uint8_t*)ptrValue, isBigEndian);
            int32_t sDenominatorValue = (int32_t) int32FromBytes(((uint8_t*)ptrValue) + 4, isBigEndian);
            stringStream << sNumeratorValue << "/" << sDenominatorValue;
        }
            break;
        default:
            break;
    }
}

std::string descriptionOfDE(DirectoryEntry& DE, bool isBigEndian) {
    std::ostringstream stringStream;
    stringStream << "Tag:0x" << std::hex << DE.tag << ", Type:";
    switch (DE.type)
    {
        case DEByte:
            stringStream << "Byte";
            break;
        case DEString:
            stringStream << "ASCII";
            break;
        case DESByte:
            stringStream << "SByte";
            break;
        case DEUndefined:
            stringStream << "Undefined";
            break;
        case DEShort:
            stringStream << "Short";
            break;
        case DESShort:
            stringStream << "SShort";
            break;
        case DELong:
            stringStream << "Long";
            break;
        case DESLong:
            stringStream << "SLong";
            break;
        case DEFloat:
            stringStream << "Float";
            break;
        case DEDouble:
            stringStream << "Double";
            break;
        case DERational:
            stringStream << "Rational";
            break;
        case DESRational:
            stringStream << "SRational";
            break;
        default:
            stringStream << "UNKNOWN";
            break;
    }
    
    stringStream << std::dec << ", Length:" << DE.length << ", Value:";
    int sizeOfValue = sizeOfDEValueType((DEValueType)DE.type);
    uint8_t* ptrValue = (uint8_t*) &DE.value;
    if (sizeOfValue * DE.length > 4)
    {
        ptrValue = DE.valueData;
    }
    printDescriptionOfDEValue(stringStream, ptrValue, (DEValueType)DE.type, isBigEndian);
    if (DE.type != DEString)
    {
        for (int i=1; i<DE.length; ++i)
        {
            stringStream << ",";
            ptrValue += sizeOfValue;
            printDescriptionOfDEValue(stringStream, ptrValue, (DEValueType)DE.type, isBigEndian);
        }
    }
    stringStream.flush();
    return stringStream.str();
}

void convertTIFFHeaderFromRaw(TIFFHeader& tiffHeader, TIFFHeaderRaw rawTIFFHeader) {
    tiffHeader.isBigEndian = (rawTIFFHeader.endian[0] == 0x4D);
    tiffHeader.TIFF_ID = int16FromBytes(rawTIFFHeader.TIFF_ID, tiffHeader.isBigEndian);
    tiffHeader.TIFF_offset = int32FromBytes(rawTIFFHeader.TIFF_offset, tiffHeader.isBigEndian);
}

void convertTIFFHeaderToRaw(TIFFHeaderRaw& rawTIFFHeader, TIFFHeader tiffHeader) {
    if (tiffHeader.isBigEndian)
    {
        rawTIFFHeader.endian[0] = 0x4D;
        rawTIFFHeader.endian[1] = 0x4D;
    }
    else
    {
        rawTIFFHeader.endian[0] = 0x49;
        rawTIFFHeader.endian[1] = 0x49;
    }
    int16Bytes(rawTIFFHeader.TIFF_ID, tiffHeader.TIFF_ID, tiffHeader.isBigEndian);
    int32Bytes(rawTIFFHeader.TIFF_offset, tiffHeader.TIFF_offset, tiffHeader.isBigEndian);
}

void convertDirectoryEntryToRaw(DirectoryEntryRaw& rawDE, DirectoryEntry DE, bool isBigEndian) {
    int16Bytes(rawDE.type, DE.type, isBigEndian);
    int16Bytes(rawDE.tag, DE.tag, isBigEndian);
    int32Bytes(rawDE.length, DE.length, isBigEndian);
    int32Bytes(rawDE.valueOrOffset, DE.value, isBigEndian);
}

void convertDirectoryEntryFromRaw(DirectoryEntry &DE, DirectoryEntryRaw rawDE, bool isBigEndian) {
    DE.type = int16FromBytes(rawDE.type, isBigEndian);
    DE.tag = int16FromBytes(rawDE.tag, isBigEndian);
    DE.length = int32FromBytes(rawDE.length, isBigEndian);
    DE.value = int32FromBytes(rawDE.valueOrOffset, isBigEndian);
}

void DirectoryEntryRelease(DirectoryEntry& DE) {
    long valueSize = sizeOfDEValueType((DEValueType)DE.type) * DE.length;
    if (valueSize > 4)
    {
        free(DE.valueData);
    }
}

bool readTIFF(TIFFHeader* outTIFFHeader, std::list<std::list<DirectoryEntry> >& outIFDList, FILE* fp) {
    TIFFHeader tiffHeader;
    if (NULL == outTIFFHeader)
    {
        outTIFFHeader = &tiffHeader;
    }
    TIFFHeaderRaw tiffHeaderRaw;
    fread(&tiffHeaderRaw, SizeOfTIFFHeaderRaw, 1, fp);
    convertTIFFHeaderFromRaw(*outTIFFHeader, tiffHeaderRaw);
    
    long tiffBeginOffset = ftell(fp);
    //    fgetpos(fp, &tiffBeginOffset);
    tiffBeginOffset -= 8;
    // Seek to first IFD struct:
    int diffOffset = outTIFFHeader->TIFF_offset - 8;
    fseek(fp, diffOffset, SEEK_CUR);
    
    releaseIFDList(outIFDList);
    
    while (true && !feof(fp))
    {
        uint16_t DEEntriesCount = 0;
        uint32_t nextIFDOffset = 0;
        fread(&DEEntriesCount, sizeof(uint16_t), 1, fp);
        DirectoryEntryRaw* rawDEEntries = new DirectoryEntryRaw[DEEntriesCount];
        fread(rawDEEntries, SizeOfDirectoryEntryRaw, DEEntriesCount, fp);
        fread(&nextIFDOffset, sizeof(uint32_t), 1, fp);
        
        std::list<DirectoryEntry> DEEntries;
        for (int iDE = 0; iDE < DEEntriesCount; ++iDE)
        {
            DirectoryEntryRaw& rawDE = rawDEEntries[iDE];
            DirectoryEntry DE;
            
            convertDirectoryEntryFromRaw(DE, rawDE, outTIFFHeader->isBigEndian);
            long valueSize = sizeOfDEValueType((DEValueType)DE.type) * DE.length;
            if (valueSize > 4)
            {
                uint8_t* valueData = (uint8_t*) malloc(valueSize);
                long currentPosition = ftell(fp);
                DE.dataOffsetInFile = tiffBeginOffset + DE.value;
                fseek(fp, tiffBeginOffset + DE.value, SEEK_SET);
                fread(valueData, valueSize, 1, fp);
                DE.valueData = valueData;
                fseek(fp, currentPosition, SEEK_SET);
            }
            
            DEEntries.push_back(DE);
        }
        outIFDList.push_back(DEEntries);
        delete[] rawDEEntries;
        
        if (0 == nextIFDOffset)
        {
            break;
        }
        else
        {
            fseek(fp, tiffBeginOffset + nextIFDOffset, SEEK_SET);
        }
    }
    fclose(fp);
    return true;
}

void writeTIFF(FILE* fp, TIFFHeader tiffHeader, void* data, uint32_t dataSessionSize, std::list<std::list<DirectoryEntry> >& IFDList) {
    TIFFHeaderRaw rawTIFFHeader;
    convertTIFFHeaderToRaw(rawTIFFHeader, tiffHeader);
    
    int32_t currentIFDOffset = SizeOfTIFFHeaderRaw + dataSessionSize;
    int32Bytes(rawTIFFHeader.TIFF_offset, currentIFDOffset, tiffHeader.isBigEndian);
    
    IFDStructMetaData* IFDStructs = (IFDStructMetaData*) malloc(sizeof(IFDStructMetaData) * IFDList.size());
    std::list<std::list<DirectoryEntry> >::iterator iIFDList = IFDList.begin();
    int iIFDMeta = 0;
    for (; iIFDList != IFDList.end(); iIFDMeta++, iIFDList++)
    {
        std::list<DirectoryEntry>& DEList = *iIFDList;
        IFDStructMetaData& IFD = IFDStructs[iIFDMeta];
        IFD.DE_count = DEList.size();
        IFD.nextIFDOffset = currentIFDOffset + SizeOfIFDStructMetaData + SizeOfDirectoryEntryRaw * IFD.DE_count;
        for (std::list<DirectoryEntry>::iterator iDE = DEList.begin(); iDE != DEList.end(); iDE++)
        {
            DirectoryEntry& DE = *iDE;
            size_t valueSize = sizeOfDEValueType((DEValueType)DE.type) * DE.length;
            if (valueSize > 4)
            {
                IFD.nextIFDOffset += valueSize;
            }
        }
        currentIFDOffset = IFD.nextIFDOffset;
    }
    if (iIFDMeta > 0)
    {
        IFDStructs[iIFDMeta - 1].nextIFDOffset = 0;
    }
    
    fwrite(&rawTIFFHeader, SizeOfTIFFHeaderRaw, 1, fp);
    fwrite(data, dataSessionSize, 1, fp);
    
    int32_t dataWritePosition = SizeOfTIFFHeaderRaw + dataSessionSize;
    iIFDList = IFDList.begin();
    iIFDMeta = 0;
    for (; iIFDList != IFDList.end(); iIFDMeta++, iIFDList++)
    {
        IFDStructMetaData& IFD = IFDStructs[iIFDMeta];
        dataWritePosition += (SizeOfIFDStructMetaData + SizeOfDirectoryEntryRaw * IFD.DE_count);
        
        uint8_t DE_count[2];
        int16Bytes(DE_count, IFD.DE_count, tiffHeader.isBigEndian);
        fwrite(DE_count, sizeof(DE_count), 1, fp);
        
        std::list<DirectoryEntry>& DEList = *iIFDList;
        for (std::list<DirectoryEntry>::iterator iDE = DEList.begin(); iDE != DEList.end(); iDE++)
        {
            DirectoryEntry& DE = *iDE;
            DirectoryEntryRaw rawDE;
            convertDirectoryEntryToRaw(rawDE, DE, tiffHeader.isBigEndian);
            int32_t valueSize = sizeOfDEValueType((DEValueType)DE.type) * DE.length;
            if (valueSize > 4)
            {
                int32Bytes(rawDE.valueOrOffset, dataWritePosition, tiffHeader.isBigEndian);
                dataWritePosition += valueSize;
            }
            fwrite(&rawDE, SizeOfDirectoryEntryRaw, 1, fp);
        }
        
        uint8_t nextIFDOffset[4];
        int32Bytes(nextIFDOffset, IFD.nextIFDOffset, tiffHeader.isBigEndian);
        fwrite(nextIFDOffset, sizeof(nextIFDOffset), 1, fp);
        
        for (std::list<DirectoryEntry>::iterator iDE = DEList.begin(); iDE != DEList.end(); iDE++)
        {
            DirectoryEntry& DE = *iDE;
            int32_t valueSize = sizeOfDEValueType((DEValueType)DE.type) * DE.length;
            if (valueSize > 4)
            {
                fwrite(DE.valueData, valueSize, 1, fp);
            }
        }
        
        dataWritePosition = IFD.nextIFDOffset;
    }
    
    free(IFDStructs);
}

void printIFDList(std::ostream& outputStream, TIFFHeader tiffHeader, std::list<std::list<DirectoryEntry> >& IFDList) {
    int numIFD = 0;
    for (std::list<std::list<DirectoryEntry> >::iterator iIFD = IFDList.begin(); iIFD != IFDList.end(); iIFD++)
    {
        std::list<DirectoryEntry>& DEEntries = *iIFD;
        outputStream << "IFD#" << (numIFD++) << " contains " << DEEntries.size() << " DE entries:" << std::endl;
        int numDE = 0;
        for (std::list<DirectoryEntry>::iterator iDE = DEEntries.begin(); iDE != DEEntries.end(); iDE++)
        {
            DirectoryEntry& DE = *iDE;
            outputStream << "DE#" << (numDE++) << " : " << descriptionOfDE(DE, tiffHeader.isBigEndian) << std::endl;;
        }
        outputStream << std::endl;
    }
}

void releaseIFDList(std::list<std::list<DirectoryEntry> >& IFDList) {
    for (std::list<std::list<DirectoryEntry> >::iterator iIFD = IFDList.begin(); iIFD != IFDList.end(); iIFD++)
    {
        std::list<DirectoryEntry>& DEEntries = *iIFD;
        for (std::list<DirectoryEntry>::iterator iDE = DEEntries.begin(); iDE != DEEntries.end(); iDE++)
        {
            DirectoryEntry& DE = *iDE;
            DirectoryEntryRelease(DE);
        }
        DEEntries.clear();
    }
    IFDList.clear();
}

/*
bool EXIFHeaderReadFromFile(ExifHeader* outExifHeader, IFDEntryList* outEntryList, IFDEntryList* outSubEntryList, const char* jpegPath) {
    ExifHeader retExifHeader;
    if (NULL == outExifHeader)
    {
        outExifHeader = &retExifHeader;
    }
    
    FILE* fp = fopen(jpegPath, "rb+");
    if (!fp)
    {
        return false;
    }
    uint8_t pilotMarker[2] = {0,0};
    ALOGE("#PreviewStuck# EXIFHeaderReadFromFile() #0");
    while ((pilotMarker[0] != EXIF_PILOT || pilotMarker[1] != EXIF_MARKER) && !feof(fp))
    {
        pilotMarker[0] = pilotMarker[1];
        fread(pilotMarker + 1, 1, 1, fp);
    }
    if (feof(fp))
    {
        fclose(fp);
        ALOGE("#PreviewStuck# EXIFHeaderReadFromFile() #N");
        return false;
    }
    
}

void IFDEntryPrint(IFDEntry* entry) {
    if (NULL == entry)
        return;
    
    if (entry->length > 4)
        printf("{tag=%04x, type=%04x, length=%d, valueData='%s'}\n", entry->tag, entry->type, entry->length, entry->valueData);
    else
        printf("{tag=%04x, type=%04x, length=%d, value=%d}\n", entry->tag, entry->type, entry->length, entry->value);
}

void IFDEntryListPrint(IFDEntryList* entryList) {
    if (NULL == entryList)
        return;
    
    printf("numberOfEntries = %d\n{", entryList->numberOfEntries);
    int i;
    for (i=0; i<entryList->numberOfEntries; ++i)
    {
        printf("    ");
        IFDEntryPrint(entryList->entries + i);
    }
    printf("}\n");
}

bool IFDEntryListInit(IFDEntryList* entryList) {
    if (NULL == entryList)
        return false;
    else
    {
        entryList->numberOfEntries = 0;
        entryList->entries = NULL;
        return true;
    }
}

void IFDEntryRelease(IFDEntry* entry) {
    if (NULL == entry)
        return;
    
    if (entry->length > 4)
    {
        free(entry->valueData);
    }
}

void IFDEntryListRelease(IFDEntryList* entryList) {
    if (NULL == entryList)
        return;
    
    int i;
    for (i=0; i<entryList->numberOfEntries; ++i)
    {
        IFDEntryRelease(entryList->entries + i);
    }
    free(entryList->entries);
}
//*/
#define EXTENSION_TAG "MadV360"

void writeExtensionToFile(const char* filePath, const void* data, int32_t length) {
    FILE* fp = fopen(filePath, "ab+");
    fwrite(data, length, 1, fp);
    fwrite(&length, sizeof(int32_t), 1, fp);
    fwrite(EXTENSION_TAG, strlen(EXTENSION_TAG), 1, fp);
    fclose(fp);
}

int readExtensionFromFile(void** pOutData, const char* filePath) {
    FILE* fp = fopen(filePath, "rb+");
    fseek(fp, 0, SEEK_END);
    int tagLength = strlen(EXTENSION_TAG);
    fseek(fp, -tagLength, SEEK_END);
    char* tag = (char*)malloc(tagLength + 1);
    fread(tag, tagLength, 1, fp);
    tag[tagLength] = '\0';
    if (0 != strcmp(tag, EXTENSION_TAG))
    {
        fclose(fp);
		free(tag);
        return 0;
    }
    else
    {
        int32_t length;
        fseek(fp, -tagLength - sizeof(int32_t), SEEK_END);
        fread(&length, sizeof(int32_t), 1, fp);
        if (NULL == *pOutData)
        {
            *pOutData = malloc(length);
        }
        fseek(fp, -tagLength - sizeof(int32_t) - length, SEEK_END);
        fread(*pOutData, length, 1, fp);
        fclose(fp);
		free(tag);
		return length;
    }
}

long readLUTOffsetInJPEG(const char* jpegPath) {
    /*
    MadvEXIFExtension madvExt = readMadvEXIFExtensionFromJPEG(NULL, jpegPath);
    if (0 == madvExt.sceneType)
    {
        return -1;
    }
    //*/
    FILE* fpJPEG = fopen(jpegPath, "rb+");
    fseek(fpJPEG, -4, SEEK_END);
    long fileSize = ftell(fpJPEG);
    int32_t lutSize = 0;
    fread(&lutSize, 4, 1, fpJPEG);
    fclose(fpJPEG);
    if (lutSize <= 0 || lutSize >= fileSize)
    {
        ALOGE("lutOffsetInJPEG = %d of JPEG:'%s'", lutSize, jpegPath);
        return -1;
    }
    
    return fileSize - lutSize;
}

void MadvEXIFExtensionReset(MadvEXIFExtension& ext) {
    ext.width = 0;
    ext.height = 0;
    ext.gyroMatrixBytes = 0;
    ext.sceneType = 0;
    ext.withEmbeddedLUT = false;
    ext.embeddedLUTOffset = 0;
    
    ext.cameraParams.leftX = 0;
    ext.cameraParams.leftY = 0;
    ext.cameraParams.rightX = 0;
    ext.cameraParams.rightY = 0;
    ext.cameraParams.ratio = 0;
    ext.cameraParams.yaw = 0;
    ext.cameraParams.pitch = 0;
    ext.cameraParams.roll = 0;
    for (int i=0; i<9; ++i) ext.cameraParams.gyroMatrix[i] = 0.f;
    ext.cameraParams.gyroMatrix[0] = ext.cameraParams.gyroMatrix[4] = ext.cameraParams.gyroMatrix[8] = 1.f;
}

MadvEXIFExtension readMadvEXIFExtensionFromJPEG(const char* jpegPath) {
    MadvEXIFExtension ret;
    MadvEXIFExtensionReset(ret);
    
    if (!jpegPath)
        return ret;
//#ifndef TARGET_OS_ANDROID
    bool isMADVMaker = false;
    bool isMADVModel = false;
    try
    {
        Exiv2::Image::AutoPtr image = Exiv2::ImageFactory::open(jpegPath);
        assert(image.get() != 0);
        image->readMetadata();
        Exiv2::ExifData &exifData = image->exifData();
        if (exifData.empty())
        {
            //std::string error(jpegPath);
            //error += ": No Exif data found in the file";
            //throw Exiv2::Error(1, error);
            MadvEXIFExtensionReset(ret);
            return ret;
        }
        
        const char* ValidModelNamePrefixes[] = {"MJXJ", "QJXJ"};
        
        int itemsLeft = 6;
        Exiv2::ExifData::const_iterator end = exifData.end();
        for (Exiv2::ExifData::const_iterator i = exifData.begin(); i != end; ++i)
        {
            int tag = i->tag();
            const Exiv2::Value& value = i->value();
            switch (tag)
            {
                case TAG_USER_COMMENT:
                {
                    ALOGE("TAG_USER_COMMENT : i->count() = %ld", (long)i->count());
                    if (i->count() == sizeof(ret.cameraParams.data))
                    {
                        ret.gyroMatrixBytes = 36;
                        value.copy(ret.cameraParams.data, Exiv2::bigEndian);
                    }
                    else if (i->count() == sizeof(ret.cameraParams.gyroMatrix))
                    {
                        ret.gyroMatrixBytes = 36;
                        value.copy((unsigned char*)ret.cameraParams.gyroMatrix, Exiv2::bigEndian);
                    }
                    else
                    {
                        ret.gyroMatrixBytes = 0;
                    }
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_SCENE_TYPE:
                {
                    ret.sceneType = (int) value.toLong();
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_IMAGE_MAKE:
                {
                    if (value.toString() == "MADV")
                    {
                        isMADVMaker = true;
                    }
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_LENS_SERIALNUMBER:
                {
                    int scaned = sscanf(value.toString().c_str(), "%f;%f;%f;%f;%f;%f;%f;%f", &ret.cameraParams.leftX, &ret.cameraParams.leftY, &ret.cameraParams.rightX, &ret.cameraParams.rightY, &ret.cameraParams.ratio, &ret.cameraParams.yaw, &ret.cameraParams.pitch, &ret.cameraParams.roll);
                    if (scaned != 8)
                    {
                        ret.cameraParams.ratio = 0;
                    }
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_IMAGE_MODEL:
                {
                    std::string modelName = value.toString();
                    const char* cstrModelName = modelName.c_str();
                    for (int iModel = sizeof(ValidModelNamePrefixes) / sizeof(ValidModelNamePrefixes[0]) - 1; iModel >= 0; --iModel)
                    {
                        const char* validModelName = ValidModelNamePrefixes[iModel];
                        if (0 == strncmp(cstrModelName, validModelName, strlen(validModelName)))
                        {
                            isMADVModel = true;
                            break;
                        }
                    }
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_FILE_SOURCE:
                {
                    ret.withEmbeddedLUT = (value.toLong() != 0);
                    ALOGE("TAG_FILE_SOURCE = 0x%lx", value.toLong());
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                default:
                    break;
            }
        }
    }
    //catch (std::exception& e) {
    //catch (Exiv2::AnyError& e) {
    catch (Exiv2::Error& e)
    {
        //std::cout << "Caught Exiv2 exception '" << e.what() << "'\n";
        //return -1;
    }
    /*
#else
    char* data = NULL;
    ALOGE("#PreviewStuck# readMadvEXIFExtensionFromJPEG() #0");
    int length = readExtensionFromFile((void**) &data, jpegPath);
    if (length > 0)
    {
        if (outMatrixData)
        {
            memcpy(outMatrixData, data, length);
        }
        
        if (*data)
        {
            free(data);
        }
        
        ret.gyroMatrixBytes = length;
    }
    
    ExifHeader exifHeader;
    IFDEntryList entryList, subEntryList;
    IFDEntryListInit(&entryList);
    IFDEntryListInit(&subEntryList);
    ALOGE("#PreviewStuck# readMadvEXIFExtensionFromJPEG() #1");
    bool success = EXIFHeaderReadFromFile(&exifHeader, &entryList, &subEntryList, jpegPath);
    ALOGE("#PreviewStuck# readMadvEXIFExtensionFromJPEG() #2");
    if (success)
    {
        bool isDataCreated = false;
        int dataLength = 0;
        IFDEntryListPrint(&entryList);
        IFDEntryListPrint(&subEntryList);
        int i;
        for (i=0; i<subEntryList.numberOfEntries; ++i)
        {
            if (0 == ret.gyroMatrixBytes && TAG_USER_COMMENT == subEntryList.entries[i].tag && 36 == subEntryList.entries[i].length)
            {
                if (!outMatrixData)
                {
                    isDataCreated = true;
                    outMatrixData = (float*) malloc(subEntryList.entries[i].length);
                }
                
                int32_t* pIntDst = (int32_t*) outMatrixData;
                uint8_t* pSrc = subEntryList.entries[i].valueData;
                dataLength = subEntryList.entries[i].length;
                ret.gyroMatrixBytes = dataLength;
                int j;
                for (j=0; j<subEntryList.entries[i].length; j+=4)
                {
                    *(pIntDst++) = int32FromBytes(pSrc, exifHeader.isBigEndian);
                    pSrc += 4;
                }
                ALOGE("#Gyro# readMadvEXIFExtensionFromJPEG : {%0.3f,%0.3f,%0.3f; %0.3f,%0.3f,%0.3f; %0.3f,%0.3f,%0.3f}", outMatrixData[0], outMatrixData[1], outMatrixData[2], outMatrixData[3], outMatrixData[4], outMatrixData[5], outMatrixData[6], outMatrixData[7], outMatrixData[8]);
                writeExtensionToFile(jpegPath, outMatrixData, dataLength);
            }
            else if (TAG_SCENE_TYPE == subEntryList.entries[i].tag)
            {
                ret.sceneType = subEntryList.entries[i].value;
            }
        }
        ALOGE("#PreviewStuck# readMadvEXIFExtensionFromJPEG() #3");
        IFDEntryListRelease(&entryList);
        IFDEntryListRelease(&subEntryList);
        
        if (isDataCreated)
        {
            free(outMatrixData);
        }
    }
#endif
     //*/
_EXIT:
    if (ret.withEmbeddedLUT)
    {
        ret.embeddedLUTOffset = readLUTOffsetInJPEG(jpegPath);
    }
    
    if (isMADVMaker && isMADVModel)
    {
        if (0 != ret.sceneType)
        {
            ret.sceneType = StitchTypeFishEye;
        }
    }
    else
    {
        if (StitchTypeFishEye != ret.sceneType)
        {
            ret.sceneType = StitchTypeStitched;
        }
        MadvEXIFExtensionReset(ret);
    }
    return ret;
}

MadvEXIFExtension readMadvEXIFExtensionFromRaw(const char* rawPath, TIFFHeader* outTIFFHeader, std::list<std::list<DirectoryEntry> >& outIFDList) {
    MadvEXIFExtension ret;
    MadvEXIFExtensionReset(ret);
    
    if (!rawPath)
        return ret;
    //#ifndef TARGET_OS_ANDROID
    bool isMADVMaker = false;
    bool isMADVModel = false;
    FILE* fp = fopen(rawPath, "rb+");
    readTIFF(outTIFFHeader, outIFDList, fp);
    //printIFDList(std::cout, *outTIFFHeader, outIFDList);
    fclose(fp);
    if (0 == outIFDList.size())
    {
        //std::string error(jpegPath);
        //error += ": No Exif data found in the file";
        //throw Exiv2::Error(1, error);
        MadvEXIFExtensionReset(ret);
        return ret;
    }
    
    const char* ValidModelNamePrefixes[] = {"MJXJ", "QJXJ"};
    
    int itemsLeft = 9;
    for (std::list<std::list<DirectoryEntry> >::iterator iIFD = outIFDList.begin(); iIFD != outIFDList.end(); iIFD++)
    {
        std::list<DirectoryEntry>& DEList = *iIFD;
        for (std::list<DirectoryEntry>::iterator iDE = DEList.begin(); iDE != DEList.end(); iDE++)
        {
            DirectoryEntry& DE = *iDE;
            size_t sizeOfValue = sizeOfDEValueType((DEValueType) DE.type) * DE.length;
            switch (DE.tag)
            {
                case TAG_DNG_WIDTH:
                {
                    ret.width = DE.value;
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_DNG_HEIGHT:
                {
                    ret.height = DE.value;
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_USER_COMMENT:
                {
                    if (sizeOfValue >= sizeof(ret.cameraParams.data))
                    {
                        ret.gyroMatrixBytes = 36;
                        memcpy(ret.cameraParams.data, DE.valueData, sizeOfValue);
                    }
                    else if (sizeOfValue >= sizeof(ret.cameraParams.gyroMatrix))
                    {
                        ret.gyroMatrixBytes = 36;
                        memcpy(ret.cameraParams.gyroMatrix, DE.valueData, sizeOfValue);
                    }
                    else
                    {
                        ret.gyroMatrixBytes = 0;
                    }
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_SCENE_TYPE:
                {
                    ret.sceneType = (int) sizeOfValue;
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_IMAGE_MAKE:
                {
                    const char* makerName = (sizeOfValue > 4 ? (const char*)DE.valueData : (const char*)&DE.value);
                    if (0 == strcmp(makerName, "MADV"))
                    {
                        isMADVMaker = true;
                    }
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_LENS_SERIALNUMBER:
                {
                    const char* valueString = (sizeOfValue > 4 ? (const char*)DE.valueData : (const char*)&DE.value);
                    int scaned = sscanf(valueString, "%f;%f;%f;%f;%f;%f;%f;%f", &ret.cameraParams.leftX, &ret.cameraParams.leftY, &ret.cameraParams.rightX, &ret.cameraParams.rightY, &ret.cameraParams.ratio, &ret.cameraParams.yaw, &ret.cameraParams.pitch, &ret.cameraParams.roll);
                    if (scaned != 8)
                    {
                        ret.cameraParams.ratio = 0;
                    }
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_IMAGE_MODEL:
                {
                    const char* cstrModelName = (sizeOfValue > 4 ? (const char*)DE.valueData : (const char*)&DE.value);
                    for (int iModel = sizeof(ValidModelNamePrefixes) / sizeof(ValidModelNamePrefixes[0]) - 1; iModel >= 0; --iModel)
                    {
                        const char* validModelName = ValidModelNamePrefixes[iModel];
                        if (0 == strncmp(cstrModelName, validModelName, strlen(validModelName)))
                        {
                            isMADVModel = true;
                        }
                    }
                    
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_FILE_SOURCE:
                {
                    ret.withEmbeddedLUT = (DE.value != 0);
                    ALOGE("TAG_FILE_SOURCE = %d", DE.value);
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                case TAG_DNG_STITCH_LUT:
                {
                    ret.embeddedLUTOffset = DE.dataOffsetInFile;
                    if (0 == --itemsLeft)
                    {
                        goto _EXIT;
                    }
                }
                    break;
                default:
                    break;
            }
        }
    }
    
_EXIT:
    if (isMADVMaker && isMADVModel)
    {
        if (0 != ret.sceneType)
        {
            ret.sceneType = StitchTypeFishEye;
        }
    }
    else
    {
        if (StitchTypeFishEye != ret.sceneType)
        {
            ret.sceneType = StitchTypeStitched;
        }
        MadvEXIFExtensionReset(ret);
    }
    return ret;
}

/*
int readGyroDataFromJPEG(float* outMatrixData, const char* jpegPath) {
    if (!jpegPath)
        return 0;
    //TODO: Check if is MadV picture
    char* data = NULL;
    int length = readExtensionFromFile((void**) &data, jpegPath);
    if (length > 0)
    {
        if (outMatrixData)
        {
            memcpy(outMatrixData, data, length);
        }

        if (*data)
        {
            free(data);
        }

        return length;
    }
    else
    {
        ExifHeader exifHeader;
        IFDEntryList entryList, subEntryList;
        IFDEntryListInit(&entryList);
        IFDEntryListInit(&subEntryList);
        bool success = EXIFHeaderReadFromFile(&exifHeader, &entryList, &subEntryList, jpegPath);
        if (success)
        {
            bool isDataCreated = false;
            int dataLength = 0;
            IFDEntryListPrint(&entryList);
            IFDEntryListPrint(&subEntryList);
            int i;
            for (i=0; i<subEntryList.numberOfEntries; ++i)
            {
                if (TAG_USER_COMMENT == subEntryList.entries[i].tag && 36 == subEntryList.entries[i].length)
                {
                    if (!outMatrixData)
                    {
                        isDataCreated = true;
                        outMatrixData = (float*) malloc(subEntryList.entries[i].length);
                    }

                    int32_t* pIntDst = (int32_t*) outMatrixData;
                    uint8_t* pSrc = subEntryList.entries[i].valueData;
                    dataLength = subEntryList.entries[i].length;
                    int j;
                    for (j=0; j<subEntryList.entries[i].length; j+=4)
                    {
                        *(pIntDst++) = int32FromBytes(pSrc, exifHeader.isBigEndian);
                        pSrc += 4;
                    }

                    break;
                }
            }
            IFDEntryListRelease(&entryList);
            IFDEntryListRelease(&subEntryList);

            writeExtensionToFile(jpegPath, outMatrixData, dataLength);

            if (isDataCreated)
            {
                free(outMatrixData);
            }

            return dataLength;
        }
    }
    return 0;
}

int readSceneTypeFromJPEG(const char* jpegPath) {
    if (!jpegPath) return 0;
    int ret = 0;
    //TODO: Check if is MadV picture
    ExifHeader exifHeader;
    IFDEntryList entryList, subEntryList;
    IFDEntryListInit(&entryList);
    IFDEntryListInit(&subEntryList);
    bool success = EXIFHeaderReadFromFile(&exifHeader, &entryList, &subEntryList, jpegPath);
    if (success)
    {
        IFDEntryListPrint(&entryList);
        IFDEntryListPrint(&subEntryList);
        int i;
        for (i=0; i<subEntryList.numberOfEntries; ++i)
        {
            if (TAG_SCENE_TYPE == subEntryList.entries[i].tag)
            {
                ret = subEntryList.entries[i].value;
                break;
            }
        }
        IFDEntryListRelease(&entryList);
        IFDEntryListRelease(&subEntryList);
    }
    return ret;
}
//*/
#pragma mark    EXIFDataBundle(Impl)

class EXIFDataBundleImpl {
public:
    
    virtual ~EXIFDataBundleImpl();
    
    EXIFDataBundleImpl(const char* jpegPath);
    
    std::string getStringValue(const char* key, int index=0);
    
    long getLongValue(const char* key, int index=0);
    
    int getShortValue(const char* key, int index=0);
    
    std::pair<int32_t, int32_t> getRationalValue(const char* key, int index=0);
    
    float getGPSCoordinate(const char* key);
    
private:
    
    Exiv2::Image::AutoPtr _image;
};

EXIFDataBundleImpl::~EXIFDataBundleImpl() {
    _image.release();
}

EXIFDataBundleImpl::EXIFDataBundleImpl(const char* jpegPath) {
    _image = Exiv2::ImageFactory::open(jpegPath);
    assert(_image.get() != 0);
    _image->readMetadata();
}

std::string EXIFDataBundleImpl::getStringValue(const char *key, int index) {
    Exiv2::ExifData& exifData = _image->exifData();
    Exiv2::ExifKey exifKey(key);
    Exiv2::ExifData::iterator pos = exifData.findKey(exifKey);
    if (pos != exifData.end())
    {
        return pos->getValue()->toString(index);
    }
    else
    {
        return "";
    }
}

long EXIFDataBundleImpl::getLongValue(const char *key, int index) {
    Exiv2::ExifData& exifData = _image->exifData();
    Exiv2::ExifKey exifKey(key);
    Exiv2::ExifData::iterator pos = exifData.findKey(exifKey);
    if (pos != exifData.end())
    {
        return pos->getValue()->toLong(index);
    }
    else
    {
        return 0;
    }
}

int EXIFDataBundleImpl::getShortValue(const char* key, int index) {
    Exiv2::ExifData& exifData = _image->exifData();
    Exiv2::ExifKey exifKey(key);
    Exiv2::ExifData::iterator pos = exifData.findKey(exifKey);
    if (pos != exifData.end())
    {
        return (int) pos->getValue()->toLong(index);
    }
    else
    {
        return 0;
    }
}

std::pair<int32_t, int32_t> EXIFDataBundleImpl::getRationalValue(const char* key, int index) {
    Exiv2::ExifData& exifData = _image->exifData();
    Exiv2::ExifKey exifKey(key);
    Exiv2::ExifData::iterator pos = exifData.findKey(exifKey);
    if (pos != exifData.end())
    {
        Exiv2::Rational rationalValue = pos->getValue()->toRational(index);
        return rationalValue;
    }
    else
    {
        return std::make_pair(0, 0);
    }
}

inline float rationalToFloat(Exiv2::Rational rational) {
    return 0.f == (float)rational.second ? 0.f : (float)rational.first / (float)rational.second;
}

float EXIFDataBundleImpl::getGPSCoordinate(const char* key) {
    Exiv2::ExifData& exifData = _image->exifData();
    Exiv2::ExifKey exifKey(key);
    Exiv2::ExifData::iterator pos = exifData.findKey(exifKey);
    if (pos != exifData.end())
    {
        Exiv2::Rational degree = pos->getValue()->toRational(0);
        Exiv2::Rational minute = pos->getValue()->toRational(1);
        Exiv2::Rational second = pos->getValue()->toRational(2);
        return rationalToFloat(degree) + rationalToFloat(minute) / 60.f + rationalToFloat(second) / 3600.f;
    }
    else
    {
        return 0.f;
    }
}

#pragma mark    EXIFDataBundle

EXIFDataBundle::~EXIFDataBundle() {
    delete (EXIFDataBundleImpl*)_impl;
}

EXIFDataBundle::EXIFDataBundle(const char* jpegPath) {
    EXIFDataBundleImpl* impl = new EXIFDataBundleImpl(jpegPath);
    _impl = impl;
}

std::string EXIFDataBundle::getStringValue(const char *key, int index) {
    EXIFDataBundleImpl* impl = (EXIFDataBundleImpl*)_impl;
    return impl ? impl->getStringValue(key, index) : "";
}

long EXIFDataBundle::getLongValue(const char *key, int index) {
    EXIFDataBundleImpl* impl = (EXIFDataBundleImpl*)_impl;
    return impl ? impl->getLongValue(key, index) : 0;
}

int EXIFDataBundle::getShortValue(const char* key, int index) {
    EXIFDataBundleImpl* impl = (EXIFDataBundleImpl*)_impl;
    return impl ? impl->getShortValue(key, index) : 0;
}

std::pair<int32_t, int32_t> EXIFDataBundle::getRationalValue(const char* key, int index) {
    EXIFDataBundleImpl* impl = (EXIFDataBundleImpl*)_impl;
    return impl ? impl->getRationalValue(key, index) : std::make_pair(0, 0);
}

std::string EXIFDataBundle::getRationalString(const char* key, int index) {
    std::pair<int32_t, int32_t> rationalValue = getRationalValue(key, index);
    std::ostringstream ostr;
    ostr << rationalValue.first << "/" << rationalValue.second;
    return ostr.str();
}

std::string EXIFDataBundle::getRationalStringFraction(const char* key, int index) {
    std::pair<int32_t, int32_t> rationalValue = getRationalValue(key, index);
    std::ostringstream ostr;
    if (0 != rationalValue.first) {
        if (0 != rationalValue.second && 1 != rationalValue.second) {
            if (rationalValue.first < rationalValue.second) {
                float temp = ((float) rationalValue.second) / rationalValue.first;
                int first = 1;
                int second = (int) (temp + 0.5) > (int) temp ? (int) temp + 1 : (int) temp;
                if (first == second) {
                    ostr << 1;
                    return ostr.str();
                } else {
                    ostr << first << "/" << second;
                    return ostr.str();
                }
            } else if (rationalValue.first > rationalValue.second) {
                float temp = ((float) rationalValue.first) / rationalValue.second;
                int first = (int) (temp + 0.5) > (int) temp ? (int) temp + 1 : (int) temp;
                ostr << first;
                return ostr.str();
            } else {
                ostr << 1;
                return ostr.str();
            }
        } else {
            ostr << rationalValue.first;
            return ostr.str();
        }
    } else {
        ostr << 0;
        return ostr.str();
    }
}

std::string EXIFDataBundle::getRationalStringDecimal(const char *key, int index) {
    std::pair<int32_t, int32_t> rationalValue = getRationalValue(key, index);
    std::ostringstream ostr;
    if (0 != rationalValue.first) {
        if (0 > rationalValue.first) {
            float temp = ((float) abs(rationalValue.first)) / rationalValue.second;
            ostr << "-" << temp;
            return ostr.str();
        } else {
            float temp = ((float) rationalValue.first) / rationalValue.second;
            ostr << temp;
            return ostr.str();
        }
    } else {
        ostr << 0;
        return ostr.str();
    }
}

float EXIFDataBundle::getRationalFloatValue(const char* key, int index) {
    std::pair<int32_t, int32_t> rationalValue = getRationalValue(key, index);
    return 0.f == (float)rationalValue.second ? 0.f : (float)rationalValue.first / (float)rationalValue.second;
}

float EXIFDataBundle::getGPSCoordinate(const char* key) {
    EXIFDataBundleImpl* impl = (EXIFDataBundleImpl*)_impl;
    return impl ? impl->getGPSCoordinate(key) : 0;
}
