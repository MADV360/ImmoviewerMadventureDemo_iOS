#if (defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0) || ( defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0)
//*
#include <iostream>
#include <opencv2/opencv.hpp>
//*/
#include "ImageBlender.h"
#include "EXIFParser.h"
#include "opencv2/stitching/detail/blenders.hpp"
#include "opencv2/stitching/detail/timelapsers.hpp"
#include "opencv2/stitching/detail/camera.hpp"
#include "opencv2/stitching/detail/exposure_compensate.hpp"
#include "opencv2/stitching/detail/matchers.hpp"
#include "opencv2/stitching/detail/motion_estimators.hpp"
#include "opencv2/stitching/detail/seam_finders.hpp"
#include "opencv2/stitching/detail/util.hpp"
#include "opencv2/stitching/detail/warpers.hpp"
#include "opencv2/stitching/warpers.hpp"

#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0

#include "stitchLib.h"
#pragma comment(lib, "stitchLib.lib")

#define CV_NO NO

#endif

using namespace std;
using namespace cv;
using namespace cv::detail;

/* 左右图像缝合，中间imgR取MBB处理之后的图像
img_right, MBB处理之后的图像；
img_left,	原始的Left图像.
coeff,		融合系数，从0到1；
step：		为float类型的LUT数据表，从load_lut_png函数获得。
*/
double proc_blending_mbb(cv::Mat &img_blend, cv::Mat &img_ori, cv::Mat &coeff, int step)
{
	int rows, cols, ch;
	cols = img_ori.cols;
	rows = img_ori.rows;
	ch = img_ori.channels();

	int cols_blend;
	cols_blend = img_blend.cols;

	float * p_co;

	int i, j, k;
	int left_start = 32;

	for (j = 0; j < rows; j++)
	{
		// 指向第一个缝
		uchar* d_r = img_blend.ptr<uchar>(j) +0 * ch;
		uchar* d_l = img_ori.ptr<uchar>(j)  +(cols / 4 - step) * ch;
		p_co = coeff.ptr<float>(0);

		float r, g, b;
		// 从第一个缝开始
		for (i = (0)* ch; i < (0 + step) * ch; i += 3)
		{

			r = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
			*d_l = (uchar)((r > 255) ? 255 : r);
			d_r++;
			d_l++;

			g = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
			*d_l = (uchar)((g > 255) ? 255 : g);
			d_r++;
			d_l++;

			b = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
			*d_l = (uchar)((b > 255) ? 255 : b);
			d_r++;
			d_l++;

			p_co++;
		}

		d_r = img_blend.ptr<uchar>(j) +step * ch;
		d_l = img_ori.ptr<uchar>(j)  +(cols / 4) * ch;
		p_co = coeff.ptr<float>(0);
		for (i = (0) * ch; i < (step)* ch; i += 3)
		{

			r = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
			*d_l = (uchar)((r > 255) ? 255 : r);
			d_r++; d_l++;

			g = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
			*d_l = (uchar)((g > 255) ? 255 : g);
			d_r++; d_l++;

			b = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
			*d_l = (uchar)((b > 255) ? 255 : b);
			d_r++; d_l++;

			p_co++;
		}

		// 右侧的缝：
		// 指向第一个缝
		d_r = img_blend.ptr<uchar>(j) +step * 2 * ch;
		d_l = img_ori.ptr<uchar>(j)  +(cols * 3 / 4 - step) * ch;
		p_co = coeff.ptr<float>(0);

		// 从第一个缝开始
		for (i = (0)* ch; i < (0 + step) * ch; i += 3)
		{

			r = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
			*d_l = (uchar)((r > 255) ? 255 : r);
			d_r++;
			d_l++;

			g = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
			*d_l = (uchar)((g > 255) ? 255 : g);
			d_r++;
			d_l++;

			b = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
			*d_l = (uchar)((b > 255) ? 255 : b);
			d_r++;
			d_l++;

			p_co++;
		}

		d_r = img_blend.ptr<uchar>(j) +step * 3 * ch;
		d_l = img_ori.ptr<uchar>(j)  +(cols * 3 / 4) * ch;
		p_co = coeff.ptr<float>(0);
		for (i = (0) * ch; i < (step)* ch; i += 3)
		{

			r = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
			*d_l = (uchar)((r > 255) ? 255 : r);
			d_r++; d_l++;

			g = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
			*d_l = (uchar)((g > 255) ? 255 : g);
			d_r++; d_l++;

			b = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
			*d_l = (uchar)((b > 255) ? 255 : b);
			d_r++; d_l++;

			p_co++;
		}

	}

	// 复制第二幅图像到第一幅图像；
	/*Rect roi(0, 0, left_start, rows);
	img_left(roi).copyTo(img_right(roi));

	roi = Rect(cols - left_start, 0, left_start, rows);
	img_left(roi).copyTo(img_right(roi));

	*/
	return 0;
}

// MBB blending 
class MultiBandBlending
{
public:
	MultiBandBlending()
	{

	}

	~MultiBandBlending()
	{

	}

	void Init(int nBlendWid, int wid, int hei, int type);

	void Process(cv::Mat & img_ori);

private:
	int nBlendWidth;
	int nHeight;
	int nWidth;

	cv::Rect roi_from1, roi_R_to, roi_L_to;
	cv::Mat out_img_R, out_img_L;
	cv::Rect roi_left, roi_right;

	cv::Mat mask_right, mask_left;
	int out_width, out_height;

	cv::Mat coeff_256;

	cv::Ptr<cv::detail::Blender> blender;
	std::vector<cv::Point> corners;
	std::vector<cv::Size> sizes;
};

// MBB blending 
void MultiBandBlending::Init(int nBlendWid, int wid, int hei, int type)
{
	nBlendWidth = nBlendWid;
	nHeight = hei;
	nWidth = wid;

	out_img_L = Mat::zeros(CvSize(nBlendWidth * 4, nHeight), type);
	out_img_R = Mat::zeros(CvSize(nBlendWidth * 4, nHeight), type);

	roi_left = CvRect(nWidth / 4 - nBlendWidth, 0, nBlendWidth * 2, nHeight);
	roi_right = CvRect(nWidth * 3 / 4 - nBlendWidth, 0, nBlendWidth * 2, nHeight);

	roi_L_to = CvRect(0, 0, nBlendWidth * 2, nHeight);
	roi_R_to = CvRect(nBlendWidth * 2, 0, nBlendWidth * 2, nHeight);

	// mask
	out_width = nBlendWid * 4;
	out_height = nHeight;

	mask_right = Mat::zeros(out_height, out_width, CV_8U);
	mask_left = Mat::ones(out_height, out_width, CV_8U) * 255;

	for (int i = 0; i < mask_right.rows; i++)
	{
		for (int j = out_width / 4; j < out_width * 3 / 4; j++)
		{
			*(uchar*)((mask_right.data + i * mask_right.step) + j) = 255;
		}

	}
	for (int i = 0; i < mask_left.rows; i++)
	{
		for (int j = out_width / 4; j < out_width * 3 / 4; j++)
		{
			*(uchar*)((mask_left.data + i * mask_left.step) + j) = 0;
		}

	}

	// 融合系数
	int step_256 = nBlendWid;

	coeff_256 = Mat::zeros(1, step_256, CV_32FC1);

	float* pdata2 = coeff_256.ptr<float>(0);
	for (int i = 0; i < coeff_256.cols; i++)
	{
		*pdata2++ = float(i + 0) / float(step_256);
	}

	// 准备：

	int blend_type = Blender::MULTI_BAND;
	bool try_cuda = true;
	float blend_strength = 25;	// strength of multi-blending 
	int merge_wid = 256;		// width of copied pixels

    corners.push_back(cv::Point(0, 0));
    corners.push_back(cv::Point(0, 0));
	sizes.push_back(out_img_L.size());
	sizes.push_back(out_img_L.size());

	blender = Blender::createDefault(blend_type, false);

	cv::Size dst_sz = out_img_L.size();
	float blend_width = sqrt(static_cast<float>(dst_sz.area())) * blend_strength / 100.f;

	if (blend_width < 1.f)
        blender = Blender::createDefault(Blender::CV_NO, try_cuda);
	else if (blend_type == Blender::MULTI_BAND)
	{
		MultiBandBlender* mb = dynamic_cast<MultiBandBlender*>(blender.get());
		mb->setNumBands(static_cast<int>(ceil(log(blend_width) / log(2.)) - 1.));
        std::cout << "\nMulti-band blender, number of bands: " << mb->numBands() << std::endl;
	}
	else if (blend_type == Blender::FEATHER)
	{
		FeatherBlender* fb = dynamic_cast<FeatherBlender*>(blender.get());
		fb->setSharpness(1.f / blend_width);
		std::cout << "Feather blender, sharpness: " << fb->sharpness() << std::endl;
	}
}

void MultiBandBlending::Process(Mat & img_ori)
{
	Mat result, result_mask;
	Mat rlst_8u;

	img_ori(roi_left).copyTo(out_img_L(roi_L_to));
	img_ori(roi_left).copyTo(out_img_R(roi_L_to));

	img_ori(roi_right).copyTo(out_img_L(roi_R_to));
	img_ori(roi_right).copyTo(out_img_R(roi_R_to));

	//		cv::imwrite("out_img_R.png", out_img_R);
	//		cv::imwrite("out_img_L.png", out_img_L);
	//		cv::imwrite("mask_left.png", mask_left);
	//		cv::imwrite("mask_right.png", mask_right);


	blender->prepare(corners, sizes);
	blender->feed(out_img_R, mask_right, corners[0]);
	blender->feed(out_img_L, mask_left, corners[1]);

	blender->blend(result, result_mask);

	result.convertTo(rlst_8u, CV_8UC3);

	//		cv::imwrite("rlst_8u.png", rlst_8u);

	// 处理图像左右边界的缝隙
	proc_blending_mbb(rlst_8u, img_ori, coeff_256, nBlendWidth);

	//		cv::imwrite("blended.png", img_ori);

	result.release();
	result_mask.release();
	rlst_8u.release();
}
#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
void blendImageV2(const char* destJPEGPath, const char* sourceJPEGPath, float leftOriginX, float leftOriginY, float rightOriginX, float rightOriginY, float ratio, float yaw, float pitch, float roll) {
	MadvEXIFExtension madvExt = readMadvEXIFExtensionFromJPEG(sourceJPEGPath);

	Mat img = imread(sourceJPEGPath);

	Circle circleLeft;
	Circle circleRight;

	circleLeft.radius = 850 * 2;
	circleLeft.x = leftOriginX * 2;
	circleLeft.y = leftOriginY * 2;

	circleRight.radius = 850 * 2;
	circleRight.x = rightOriginX * 2;
	circleRight.y = rightOriginY * 2;

	VecDirect dir;
	dir.yaw = yaw;
	dir.pitch = pitch;
	dir.roll = roll;

	int wid, hei;
	wid = 6912;
	hei = 3456;

	// 2，拼接/融合，输出
	cv::Mat img_output = cv::Mat::zeros(hei, wid, CV_8UC3);

	double duration;
	duration = static_cast<double>(cv::getTickCount());

	// 1，设置双球的圆心位置，旋转角度，比例系数
	MV_SetParams(circleLeft, circleRight, dir, ratio, CvSize(img.cols, img.rows), CvSize(wid, hei));
	MV_ImageStitch(img, img_output, madvExt.cameraParams.gyroMatrix);

	duration = static_cast<double>(cv::getTickCount()) - duration;
	duration /= cv::getTickFrequency();

	printf("converting time used: %f\n", duration);

	cv::imwrite(destJPEGPath, img_output);
}
#endif //#if defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0
int blendImage(const char* destJPEGPath, const char* sourceJPEGPath, int halfBlendingWidth) {
	Mat frame_input, frame_in;
	Mat out_img_R, out_img_L;
	double dur = static_cast<double>(cv::getTickCount());

	frame_in = cv::imread(sourceJPEGPath, CV_LOAD_IMAGE_COLOR);
	if (!frame_in.data)
	{
		cout << "Can't opencv input image!\n" << endl;
		return -1;
	}

	MultiBandBlending mbb;
	mbb.Init(halfBlendingWidth, frame_in.cols, frame_in.rows, frame_in.type());
	mbb.Process(frame_in);
	cv::imwrite(destJPEGPath, frame_in);

	frame_in.release();
	/*
	frame_in = cv::imread("IMG_20171110_154333_30343718.jpg", CV_LOAD_IMAGE_COLOR);
	mbb.Process(frame_in);
	cv::imwrite("out2.png", frame_in);
	//*/
	return 0;
}

/////////////////////////////////

/* 左右图像缝合，中间imgR取MBB处理之后的图像
 * img_right, MBB处理之后的图像；
 * img_left,  原始的Left图像.
 * coeff,      融合系数，从0到1；
 * step：      为float类型的LUT数据表，从load_lut_png函数获得。
 */
int proc_blending_mbb_whole(cv::Mat &img_right, cv::Mat &img_left, cv::Mat &coeff, int step)
{
    int rows, cols, ch;
    cols = img_right.cols;
    rows = img_right.rows;
    ch = img_right.channels();
    
    float * p_co;
    int i, j, k;
    int left_start = 32;
    
    for (j = 0; j < rows; j++)
    {
        // 指向第一个缝
        uchar* d_r = img_right.ptr<uchar>(j) +left_start * ch;
        uchar* d_l = img_left.ptr<uchar>(j)  +left_start * ch;
        p_co = coeff.ptr<float>(0);
        
        float r, g, b;
        // 从第一个缝开始
        for (i = (left_start)* ch; i < (left_start + step) * ch; i += 3)
        {
            r = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
            *d_r = (uchar)((r > 255) ? 255 : r);
            d_r++;
            d_l++;
            
            g = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
            *d_r = (uchar)((g > 255) ? 255 : g);
            d_r++;
            d_l++;
            
            b = (*d_r)* (*p_co) + (*d_l)* (1 - *p_co);
            *d_r = (uchar)((b > 255) ? 255 : b);
            d_r++;
            d_l++;
            
            p_co++;
        }
    }
    
    // 图像最左侧减去32列
    for (j = 0; j < rows; j++)
    {
        // 指向第二个缝
        uchar* d_r = img_right.ptr<uchar>(j) +(cols - step - left_start) * ch;
        uchar* d_l = img_left.ptr<uchar>(j)  +(cols - step - left_start) * ch;
        p_co = coeff.ptr<float>(0);
        
        float r, g, b;
        // 从第二个缝开始
        for (i = (cols - left_start - step) * ch; i < (cols - left_start) * ch; i += 3)
        {
            r = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
            *d_r++ = (uchar)((r > 255) ? 255 : r);
            d_l++;
            
            g = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
            *d_r++ = (uchar)((g > 255) ? 255 : g);
            d_l++;
            
            b = (*d_r)* (1 - *p_co) + (*d_l)* (*p_co);
            *d_r++ = (uchar)((b > 255) ? 255 : b);
            d_l++;
            
            p_co++;
        }
    }
    // 复制第二幅图像到第一幅图像；
    cv::Rect roi(0, 0, left_start, rows);
    img_left(roi).copyTo(img_right(roi));
    
    roi = cv::Rect(cols - left_start, 0, left_start, rows);
    img_left(roi).copyTo(img_right(roi));
    return 0;
}

bool blendImageWhole(const char* destImagePath, const char* sourceImagePath)
{
    if(NULL == sourceImagePath || NULL == destImagePath)
    {
        return false;
    }
    
    Mat frame_in;
    Mat out_img_L, out_img_R;
    frame_in = cv::imread(sourceImagePath, CV_LOAD_IMAGE_COLOR);
    if (!frame_in.data)
    {
        return false;
    }
    
    frame_in.copyTo(out_img_L);
    frame_in.copyTo(out_img_R);
    if (!out_img_R.data || !out_img_L.data)
    {
        return false;
    }
    
    //=====系数准备=====
    int out_width = frame_in.cols;
    int out_height = frame_in.rows;
    
    int step_256 = 256;
    cv::Mat coeff_256(1, step_256, CV_32FC1);
    float* pdata2 = coeff_256.ptr<float>(0);
    for (int i = 0; i < coeff_256.cols; i++)
    {
        *pdata2++ = float(i + 0) / float(step_256);
    }
    
    int step_16 = 16;
    cv::Mat coeff_16(1, step_16, CV_32FC1);
    float* pdata3 = coeff_16.ptr<float>(0);
    for (int i = 0; i < coeff_16.cols; i++)
    {
        *pdata3++ = float(i + 0) / float(step_16);
    }
    //=====完成系数准备=====
    
    //=====prepare the blender=====
    Ptr<Blender> blender;
    int blend_type = Blender::MULTI_BAND;
    bool try_cuda = true;
    float blend_strength = 25;    // strength of multi-blending
    int merge_wid = 256;        // width of copied pixels
    
    int num_images = 2;
    vector<cv::Point> corners(num_images);
    vector<cv::Size> sizes(num_images);
    
    blender = Blender::createDefault(blend_type, false);
    cv::Size dst_sz = out_img_R.size();
    float blend_width = sqrt(static_cast<float>(dst_sz.area())) * blend_strength / 100.f;
    
    if (blend_width < 1.f)
    {
        blender = Blender::createDefault(Blender::CV_NO, try_cuda);
    }
    else if (blend_type == Blender::MULTI_BAND)
    {
        MultiBandBlender* mb = dynamic_cast<MultiBandBlender*>(blender.get());
        mb->setNumBands(static_cast<int>(ceil(log(blend_width) / log(2.)) - 1.));
    }
    else if (blend_type == Blender::FEATHER)
    {
        FeatherBlender* fb = dynamic_cast<FeatherBlender*>(blender.get());
        fb->setSharpness(1.f / blend_width);
    }
    
    corners[0] = cv::Point(0,0); //right side image
    corners[1] = cv::Point(0, 0); // Left side image
    sizes[0] = out_img_R.size();
    sizes[1] = out_img_R.size();
    
    blender->prepare(corners, sizes);
    
    // get the masks for left and right camera
    Mat mask_left = Mat::ones(out_height, out_width, CV_8U) * 255;
    Mat mask_right = Mat::zeros(out_height, out_width, CV_8U);
    
    for (int i = 0; i < mask_right.rows; i++)
    {
        for (int j = out_width / 4; j < out_width * 3 / 4; j++)
        {
            *(uchar*)((mask_right.data + i * mask_right.step) + j) = 255;
        }
    }
    
    for (int i = 0; i < mask_left.rows; i++)
    {
        for (int j = out_width / 4; j < out_width * 3 / 4; j++)
        {
            *(uchar*)((mask_left.data + i * mask_left.step) + j) = 0;
        }
    }
    
    // blending result and mask
    Mat result, result_mask, rlst_8u;
    //=====end of blender preparing=====
    
    //开始blender
    for (int i = 0; i < out_img_R.rows; i++)
    {
        int j = out_width / 4;
        uchar r = ((uchar*)(out_img_R.data + i * out_img_R.step) )[j * 3];
        uchar g = ((uchar*)(out_img_R.data + i * out_img_R.step) )[j * 3 + 1];
        uchar b = ((uchar*)(out_img_R.data + i * out_img_R.step) )[j * 3 + 2];
        for (int j = 0; j < out_width / 4; j++)
        {
            ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3] = r;
            ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3 + 1] = g;
            ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3 + 2] = b;
        }
        
        j = out_width * 3 / 4;
        r = ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3];
        g = ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3 + 1];
        b = ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3 + 2];
        for (int j = out_width * 3 / 4; j < out_width; j++)
        {
            ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3] = r;
            ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3 + 1] = g;
            ((uchar*)(out_img_R.data + i * out_img_R.step))[j * 3 + 2] = b;
        }
    }
    
    for (int i = 0; i < out_img_L.rows; i++)
    {
        int j = out_width / 4;
        uchar r = ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3];
        uchar g = ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3 + 1];
        uchar b = ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3 + 2];
        for (int j = out_width / 4; j < out_width / 2; j++)
        {
            ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3] = r;
            ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3 + 1] = g;
            ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3 + 2] = b;
        }
        
        j = out_width * 3 / 4;
        r = ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3];
        g = ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3 + 1];
        b = ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3 + 2];
        for (int j = out_width / 2; j < out_width * 3 / 4; j++)
        {
            ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3] = r;
            ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3 + 1] = g;
            ((uchar*)(out_img_L.data + i * out_img_L.step))[j * 3 + 2] = b;
        }
    }
    
    blender->prepare(corners, sizes);
    blender->feed(out_img_R, mask_right, corners[0]);
    blender->feed(out_img_L, mask_left, corners[1]);
    
    blender->blend(result, result_mask);
    
    //处理图像左右边界的缝隙
    result.convertTo(rlst_8u, CV_8UC3);
    proc_blending_mbb_whole(rlst_8u, out_img_L, coeff_256, step_256);
    
    //写文件
    imwrite(destImagePath, rlst_8u);
    
    //释放资源
    frame_in.release();
    out_img_L.release();
    out_img_R.release();
    mask_left.release();
    mask_right.release();
    coeff_256.release();
    coeff_16.release();
    result.release();
    result_mask.release();
    rlst_8u.release();
    
    return true;
}

#endif //#if (defined(TARGET_OS_WINDOWS) && TARGET_OS_WINDOWS != 0) || ( defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0)
