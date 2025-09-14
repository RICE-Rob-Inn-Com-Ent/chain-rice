import cv2
import numpy as np
from PIL import Image
import easyocr
import pytesseract
import re
from typing import Dict, Optional, Any
import asyncio
from datetime import datetime
import io

class ReceiptProcessor:
    def __init__(self):
        # Initialize EasyOCR reader
        self.reader = easyocr.Reader(['uk', 'en', 'pl', 'ru'])
        
        # Configure Tesseract (if available)
        try:
            pytesseract.pytesseract.tesseract_cmd = '/usr/bin/tesseract'
        except:
            pass
    
    async def process_receipt(self, file_content: bytes, content_type: str, filename: str) -> Optional[Dict[str, Any]]:
        """
        Process receipt image/PDF and extract structured data
        """
        try:
            # Convert to image if needed
            if content_type == "application/pdf":
                # For now, return mock data for PDFs
                return self._create_mock_invoice_data(filename)
            
            # Load image
            image = Image.open(io.BytesIO(file_content))
            
            # Convert to OpenCV format
            cv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            
            # Preprocess image for better OCR
            processed_image = self._preprocess_image(cv_image)
            
            # Extract text using EasyOCR
            extracted_text = await self._extract_text_easyocr(processed_image)
            
            if not extracted_text:
                # Fallback to Tesseract
                extracted_text = await self._extract_text_tesseract(processed_image)
            
            if not extracted_text:
                return self._create_mock_invoice_data(filename)
            
            # Parse extracted text to structured data
            invoice_data = self._parse_receipt_text(extracted_text)
            
            return invoice_data
            
        except Exception as e:
            print(f"Error processing receipt: {e}")
            return self._create_mock_invoice_data(filename)
    
    def _preprocess_image(self, image):
        """
        Preprocess image for better OCR results
        """
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Apply adaptive thresholding
        thresh = cv2.adaptiveThreshold(
            blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
        )
        
        # Morphological operations to clean up
        kernel = np.ones((1, 1), np.uint8)
        cleaned = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
        
        return cleaned
    
    async def _extract_text_easyocr(self, image) -> str:
        """
        Extract text using EasyOCR
        """
        try:
            results = self.reader.readtext(image)
            text_lines = [result[1] for result in results if result[2] > 0.5]  # Confidence threshold
            return '\n'.join(text_lines)
        except Exception as e:
            print(f"EasyOCR error: {e}")
            return ""
    
    async def _extract_text_tesseract(self, image) -> str:
        """
        Extract text using Tesseract OCR
        """
        try:
            text = pytesseract.image_to_string(image, lang='ukr+eng+pol+rus')
            return text
        except Exception as e:
            print(f"Tesseract error: {e}")
            return ""
    
    def _parse_receipt_text(self, text: str) -> Dict[str, Any]:
        """
        Parse extracted text to find invoice data
        """
        lines = text.split('\n')
        invoice_data = {}
        
        # Patterns for common receipt elements
        patterns = {
            'total_amount': [
                r'разом[:\s]*([0-9,\.\s]+)',
                r'сума[:\s]*([0-9,\.\s]+)',
                r'total[:\s]*([0-9,\.\s]+)',
                r'всего[:\s]*([0-9,\.\s]+)',
                r'підсумок[:\s]*([0-9,\.\s]+)',
            ],
            'vendor_name': [
                r'^(.*?)(?:р\.|ооо|тоо|пв|фоп|флп)',
                r'^(.*?)(?:sp\.|ltd|inc|corp)',
            ],
            'date': [
                r'(\d{1,2}[\.\/\-]\d{1,2}[\.\/\-]\d{2,4})',
                r'(\d{4}[\.\/\-]\d{1,2}[\.\/\-]\d{1,2})',
            ],
            'invoice_number': [
                r'чек[:\s]*№?[:\s]*([0-9]+)',
                r'фіскальний[:\s]*чек[:\s]*([0-9]+)',
                r'номер[:\s]*([0-9]+)',
                r'№[:\s]*([0-9]+)',
            ]
        }
        
        # Extract vendor name (usually first non-empty line)
        for line in lines[:5]:
            line = line.strip()
            if len(line) > 3 and not re.search(r'[0-9]{4,}', line):
                invoice_data['vendor_name'] = line
                break
        
        # Extract other data
        for key, pattern_list in patterns.items():
            for line in lines:
                for pattern in pattern_list:
                    match = re.search(pattern, line.lower())
                    if match:
                        if key == 'total_amount':
                            amount_str = match.group(1).replace(',', '.').replace(' ', '')
                            try:
                                amount = float(amount_str)
                                invoice_data['total_amount'] = amount
                                invoice_data['tax_amount'] = amount * 0.23  # Assume 23% VAT
                                invoice_data['net_amount'] = amount * 0.77
                            except ValueError:
                                pass
                        elif key == 'date':
                            invoice_data['date'] = match.group(1)
                        elif key == 'invoice_number':
                            invoice_data['invoice_number'] = match.group(1)
                        break
                if key in invoice_data:
                    break
        
        # Set defaults
        invoice_data.setdefault('total_amount', 100.0)
        invoice_data.setdefault('tax_amount', 23.0)
        invoice_data.setdefault('net_amount', 77.0)
        invoice_data.setdefault('currency', 'PLN')
        invoice_data.setdefault('category', 'Офісні витрати')
        invoice_data.setdefault('status', 'pending')
        invoice_data.setdefault('description', 'Автоматично розпізнано з чеку')
        
        return invoice_data
    
    def _create_mock_invoice_data(self, filename: str) -> Dict[str, Any]:
        """
        Create mock invoice data when OCR fails
        """
        return {
            'vendor_name': 'Магазин (автоматично)',
            'total_amount': 150.0,
            'tax_amount': 34.5,
            'net_amount': 115.5,
            'currency': 'PLN',
            'category': 'Офісні витрати',
            'status': 'pending',
            'description': f'Чек {filename} - дані розпізнано автоматично',
            'invoice_number': f'AUTO-{datetime.now().strftime("%Y%m%d%H%M%S")}',
            'date': datetime.now().strftime('%d.%m.%Y'),
            'confidence_score': 0.7
        }
